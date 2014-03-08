import cPickle as pickle
from fnmatch import fnmatch
import operator
import os
import random
import traceback
import math
import csv
from multiprocessing import Process
from itertools import tee, izip_longest
import sys
import time
import numpy as np
from PIL import Image
from PIL import ImageOps
from joblib import Parallel
from joblib import delayed
# This import path ensures the appropriate modules are available
sys.path.append(os.path.join(os.path.abspath(os.path.dirname(__file__)), "cuda_convnet"))
import convnet
import options
from noccn.noccn.script import *
# This is used to parse xml files
import xml.etree.ElementTree as ET # can be speeded up using lxml possibly
import xml.dom.minidom as minidom


# Exit errors to be returned via sys.exit when the
# program does not successfully complete all jobs
NO_ERROR = 0
COULD_NOT_OPEN_IMAGE_FILE = 1
COULD_NOT_START_CONVNET = 2
COULD_NOT_SAVE_OUTPUT_FILE = 3
INVALID_COMMAND_ARGS = 4


# Accepts an image filename, and number of channels,
# processes the image into a 1D numpy array, of the
# form [R G B] with each colour collapsed into row major order
def _process_tag_item(size,channels,name):
    try:
        im = Image.open(name)
        im = ImageOps.fit(im, size, Image.ANTIALIAS)
        im_data = np.array(im)
        im_data = im_data.T.reshape(channels, -1).reshape(-1)
        im_data = im_data.astype(np.single)
        return im_data
    except:
        sys.exit(COULD_NOT_OPEN_IMAGE_FILE)


# Yields chunks of a specified size n of a list until it
# is empty.  Chunks are not guaranteed to be of size n
# if the list is not a multiple of the chunk size
def chunks(l, n):
    for i in xrange(0, len(l), n):
            yield l[i:i+n]


# Returns the next item in a list, at the same time as
# the first item.  If there is no next, it returns None
def get_next(some_iterable):
    it1, it2 = tee(iter(some_iterable))
    next(it2)
    return izip_longest(it1, it2)


# Class which runs through for a given batch of a single type
# the network defined in the run.cfg file.
class ImageRecogniser(object):
    def __init__(self,batch_size=128,channels=3,threshold=0,
                 size=(256,256),model=None,n_jobs=-1,**kwargs):
        self.batch_size = batch_size
        self.channels = channels
        self.size = size
        self.n_jobs = n_jobs
        self.model = model
        self.threshold = threshold
        vars(self).update(**kwargs) 

    # Main processing function. It works from the list of filenames
    # passed in, in 128 chunks, processing into numpy arrays and 
    # classifying with the classifier
    def __call__(self, filenames):
        batch_num = 1
        batch_means = np.zeros(((self.size[0]**2)*self.channels,1))
        start_time = time.clock()
        for filenames,next_filenames in get_next(list(chunks(filenames,self.batch_size))):
            if batch_num == 1:
                rows = Parallel(n_jobs=self.n_jobs)(
                       delayed(_process_tag_item)(self.size,self.channels,filename)
                       for filename in filenames)
            if not all_images_successfully_processed:    
                for each_filename in failed_images:
                    print each_filename
                sys.exit(COULD_NOT_OPEN_IMAGE_FILE)
            data = np.vstack([r for r in rows if r is not None]).T
            if data.shape[1] > 5:
                mean = data.mean(axis=1).reshape(((self.size[0]**2)*self.channels,1))
                data = data - mean
            #else:
		    #   mean = self.model.train_data_provider.data_mean
            #   data = data - mean
            self.model.start_predictions(data)
            if next_filenames is not None:
                rows = Parallel(n_jobs=self.n_jobs)(
                    delayed(_process_tag_item)(self.size,self.channels,filename)
		    for filename in next_filenames)
                names = [name for (r,name) in zip(rows,filenames) if r is not None];
            try:    
                self.model.finish_predictions(names,self.num_results,self.threshold)
            except:
                sys.exit(COULD_NOT_SAVE_OUTPUT_FILE)
            batch_num += 1
        

# The wrapper class for the convnet which has already been
# trained.  Which convnet gets loaded is determined by the
# run.cfg file.  It will finish a batch by pickle dumping
# each of the image files results to a *.pickle equivilent
# to the *.jpg that was given. The set size that will be in
# that result will vary between convulutional nets.  The 
# combine script takes care of reizing with appropriate spaces.
class PlantConvNet(convnet.ConvNet):
    def __init__(self, op, load_dic, dp_params={}):
        convnet.ConvNet.__init__(self,op,load_dic,dp_params)
        self.softmax_idx = self.get_layer_idx('probs', check_type='softmax')
        self.tag_names = list(self.test_data_provider.batch_meta['label_names'])
        self.b_data = None
        self.b_labels = None
        self.b_preds = None


    def import_model(self):
        self.libmodel = __import__("_ConvNet") 


    def start_predictions(self, data):
        # Run the batch through the model
        self.b_data = np.require(data, requirements='C')
        self.b_labels = np.zeros((1, data.shape[1]), dtype=np.single)
        self.b_preds = np.zeros((data.shape[1], len(self.tag_names)), dtype=np.single)
        self.libmodel.startFeatureWriter([self.b_data, self.b_labels, self.b_preds], self.softmax_idx)


    def finish_predictions(self, filenames, threshold):
        # Finish the batch
	    self.finish_batch()
        for filename,row in zip(filenames,rows):
            file_storage = open(os.path.splitext(filename)[0] + '.pickle','wb')
            pickle.dump(np.array(row),file_storage)
            file_storage.close()


    @classmethod
    def get_options_parser(cls):
        op = convnet.ConvNet.get_options_parser()
        for option in list(op.options):
            if option not in ('load_file'):
                op.delete_option(option)
        return op


# The console interpreter.  It checks whether the arguments
# are valid, and also parses the configuration files.
def console():
    if len(sys.argv) < 3:
        print 'Must give a component type and valid image file as arguments'
        sys.exit(INVALID_COMMAND_ARGS)
    valid_args = ['entire','stem','branch','leaf','fruit','flower']
    if sys.argv[1] not in valid_args:
        print 'First argument must be one of: [',
        for arg in valid_args:
            print arg + ' ',
        print ']'
        sys.exit(INVALID_COMMAND_ARGS)
    cfg = get_options(os.path.dirname(os.path.abspath(__file__))+'/run.cfg', 'run')
    cfg_options_file = cfg.get(sys.argv[1],'Type classification not found')
    cfg_data_options = get_options(cfg_options_file, 'dataset')
    creator = resolve(cfg.get('creator', 'run.ImageRecogniser'))
    try:
        conv_model = make_model(PlantConvNet,'run',cfg_options_file)
    except:
        sys.exit(COULD_NOT_START_CONVNET)
    create = creator(
        batch_size=int(cfg.get('batch-size', 128)),
        channels=int(cfg_data_options.get('channels', 3)),
        size=eval(cfg_data_options.get('size', '(256, 256)')),
        model=conv_model
        threshold=float(cfg.get('threshold',0.0)),
        )
    create(sys.argv[2:])


# Boilerplate for running the appropriate function.
if __name__ == "__main__":
    console()

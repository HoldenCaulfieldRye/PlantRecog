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

sys.path.append(os.path.join(os.path.abspath(os.path.dirname(__file__)), "cuda_convnet"))
import convnet
import options
from noccn.noccn.script import *

# This is used to parse xml files
import xml.etree.ElementTree as ET # can be speeded up using lxml possibly
import xml.dom.minidom as minidom

# Exit errors
NO_ERROR = 0
COULD_NOT_OPEN_IMAGE_FILE = 1
COULD_NOT_START_CONVNET = 2
COULD_NOT_SAVE_OUTPUT_FILE = 3
INVALID_COMMAND_ARGS = 4


# Error variables
all_images_successfully_processed = True
failed_images = []


# Constants
N_JOBS = -1
SIZE = (256,256) 


def _process_tag_item(size,channels,name):
    try:
        im = Image.open(name)
        im = ImageOps.fit(im, size, Image.ANTIALIAS)
        im_data = np.array(im)
        im_data = im_data.T.reshape(channels, -1).reshape(-1)
        im_data = im_data.astype(np.single)
        return im_data
    except:
        all_images_successfully_processed = False
        failed_images.append(name)
        return None


def chunks(l, n):
    for i in xrange(0, len(l), n):
            yield l[i:i+n]


def get_next(some_iterable):
    it1, it2 = tee(iter(some_iterable))
    next(it2)
    return izip_longest(it1, it2)


class ImageRecogniser(object):
    def __init__(self,batch_size=128,channels=3,threshold=0,
                 size=SIZE,model=None,n_jobs=N_JOBS,**kwargs):
        self.batch_size = batch_size
        self.channels = channels
        self.size = size
        self.n_jobs = n_jobs
        self.model = model
        self.threshold = threshold
        vars(self).update(**kwargs) 

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


    def finish_predictions_top_num(self, filenames, num_results, threshold):
        # Finish the batch
	    self.finish_batch()
        rows = np.argsort(self.b_preds,axis=1)[:,::-1][:,:num_results] # positions
        for i,(filename,row) in enumerate(zip(filenames,rows)):
            if self.b_preds[i,row.T[0]] >= threshold:
	        print filename + '{',
	        for value in row.T:
	            print "%s:%.03f;"%(self.tag_names[value],self.b_preds[i,value]),
            print "}"# => Actually " + actual_type + " picture of a " + actual_name


    def write_predictions(self):
        pass


    def report(self):
        pass


    @classmethod
    def get_options_parser(cls):
        op = convnet.ConvNet.get_options_parser()
        for option in list(op.options):
            if option not in ('load_file'):
                op.delete_option(option)
        return op


def console():
    if len(sys.argv) < 3:
        print 'Must give a component type and valid image file as arguments'
        sys.exit(INVALID_COMMAND_ARGS)
    valid_args = ['entire','stem','branch','leaf','fruit','flower']
    if sys.argv[1] not in valid_args:
        print 'First argument must be:',
        for arg in valid_args:
            print '[' + arg + '] ',
        print ''
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


if __name__ == "__main__":
    console()

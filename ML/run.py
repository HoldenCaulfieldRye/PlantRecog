import cPickle
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

import convnet
import options
from noccn.noccn.script import *

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
        return None


def chunks(l, n):
    """ Yield successive n-sized chunks from l.
    """
    for i in xrange(0, len(l), n):
            yield l[i:i+n]


def get_next(some_iterable):
    it1, it2 = tee(iter(some_iterable))
    next(it2)
    return izip_longest(it1, it2)


class ImageRecogniser(object):
    def __init__(self, batch_size=128,num_results=5, channels=3, 
                 size=SIZE, model=None, n_jobs=N_JOBS, **kwargs):
        self.batch_size = batch_size
        self.num_results = num_results
        self.channels = channels
        self.size = size
        self.n_jobs = n_jobs
        self.model = model
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
	    data = np.vstack([r for r in rows if r is not None]).T
            mean = data.mean(axis=1).reshape(((self.size[0]**2)*self.channels,1))
            data = data - mean
            self.model.start_predictions(data)
            if next_filenames is not None:
		rows = Parallel(n_jobs=self.n_jobs)(
		    delayed(_process_tag_item)(self.size,self.channels,filename)
		    for filename in next_filenames)
        #    self.model.finish_predictions(self.num_results)
            batch_num += 1
#        print "Tagging complete. Tagged %d images in %.02f seconds" % (len(filenames),time.clock()-start_time)
        

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
	self.finish_batch()
        print self.b_preds

    def finish_predictions(self, num_results):
        # Finish the batch
	self.finish_batch()
        print self.b_preds
	'''
        rows = np.argsort(self.b_preds,axis=1)[:,::-1][:,:num_results] # positions
        for i,row in enumerate(rows):
            for value in row.T:
                print "%s :%.02f" % (self.tag_names[value],self.b_preds[i,value]),
            print ""
	'''

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
    cfg = get_options('run.cfg', 'run')
    cfg_options_file = cfg.get(sys.argv[1],'Type classification not found')
    cfg_data_options = get_options(cfg_options_file, 'dataset')
    creator = resolve(cfg.get('creator', 'run.ImageRecogniser'))
    create = creator(
        batch_size=int(cfg.get('batch-size', 128)),
        num_results=int(cfg.get('number-of-results',5)),
        channels=int(cfg_data_options.get('channels', 3)),
        size=eval(cfg_data_options.get('size', '(256, 256)')),
        model=make_model(PlantConvNet,'run',cfg_options_file),
        )
    create(sys.argv[2:])


if __name__ == "__main__":
    sys.path.append(os.path.join(os.path.dirname(__file__), "ML"))
    console()

import cPickle
from fnmatch import fnmatch
import operator
import os
import random
import traceback
import math
import csv
from multiprocessing import Process
import sys
import time

import numpy as np
from PIL import Image
from PIL import ImageOps
from joblib import Parallel
from joblib import delayed

from .ccn import convnet
from .ccn import options
from .script import get_sections
from .script import make_model
from .script import get_options
from .script import random_seed
from .script import resolve

# This is used to parse the xml files
import xml.etree.ElementTree as ET # can be speeded up using lxml possibly

N_JOBS = -1
SIZE = (64, 64)

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

'''
Things that this script needs to do:
Accepts a cgf file.
Takes a threshold probability, a directory, a max batch size
Also accepts the standard image size from batching config
Search the directory folder for xml files and jpg files
Batch the jpg files into max of max b_size numpy array batches of 256*256 (but variable length)
Pull the output probabilities for each image
'''

def chunks(l, n):
    """ Yield successive n-sized chunks from l.
    """
    for i in xrange(0, len(l), n):
            yield l[i:i+n]


class Tagger(object):
    def __init__(self, batch_size=1000, channels=3, size=SIZE,
                 model=None, threshold=0.0, tagas=None,n_jobs=N_JOBS, more_meta=None,  **kwargs):
        self.batch_size = batch_size
        self.channels = channels
        self.size = size
        self.n_jobs = n_jobs
        self.more_meta = more_meta or {}
        self.model = model
        self.threshold = threshold
        self.tagas = tagas
        vars(self).update(**kwargs)  # O_o

    def __call__(self, all_names_and_labels, shuffle=False):
        batch_num = 1
        batch_means = np.zeros(((self.size[0]**2)*self.channels,1))
        count_correct = 0
        count_incorrect = 0
        for names_and_labels in list(chunks(all_names_and_labels,self.batch_size)):
            print "\rCategorizing batch " + `batch_num`,
	    rows = Parallel(n_jobs=self.n_jobs)(
		delayed(_process_tag_item)(self.size,self.channels,name)
		for name, label in names_and_labels)
	    data = np.vstack([r for r in rows if r is not None]).T
            mean = data.mean(axis=1).reshape(((self.size[0]**2)*self.channels,1))
            data = data - mean
            tags = self.model.make_predictions(data,self.threshold)
            for tag,(name, label) in zip(tags,names_and_labels):
                tree = ET.parse(label)
                root = tree.getroot()
                actual = root.find('Content').text
                if self.tagas != None:
			title = ET.SubElement(root, self.tagas)
			title.text = tag
                        tree.write(label)
                if tag!='Exclude' and actual!='LeafScan':
                    if tag == actual:
                        count_correct += 1
                    else:
                        count_incorrect +=1
            batch_num += 1
            print 'Correct:' + `count_correct` + '\t\t\tIncorrect:' + `count_incorrect` + '\t\t\tRatio' + `float(count_correct)/(count_correct+count_incorrect)`
            
        print 'Tagging complete'
        print 'Correct:' + `count_correct` + '\t\t\tIncorrect:' + `count_incorrect` + '\t\t\tRatio' + `float(count_correct)/(count_correct+count_incorrect)`


class TagConvNet(convnet.ConvNet):
    def __init__(self, op, load_dic, dp_params={}):
        convnet.ConvNet.__init__(self,op,load_dic,dp_params)
	self.softmax_idx = self.get_layer_idx('probs', check_type='softmax')
        self.tag_names = list(self.test_data_provider.batch_meta['label_names'])
        self.tag_names.append('Exlude')

    def make_predictions(self, data, threshold):
	# Run the batch through the model
	data = np.require(data, requirements='C')
	labels = np.zeros((1, data.shape[1]), dtype=np.single)
	preds = np.zeros((data.shape[1], len(self.tag_names)-1), dtype=np.single)
	self.libmodel.startFeatureWriter([data, labels, preds], self.softmax_idx)
	self.finish_batch()
        # Process the batch
        threshold_array = np.empty((preds.shape[0],1))
        threshold_array.fill(threshold)
        preds = np.hstack((preds,threshold_array))
        return [self.tag_names[i] for i in np.nditer(preds.argmax(axis=1))]

    def write_predictions(self):
        pass

    def report(self):
        pass

    @classmethod
    def get_options_parser(cls):
        op = convnet.ConvNet.get_options_parser()
        for option in list(op.options):
            if option not in ('gpu', 'load_file'):
                op.delete_option(option)
        return op


def find(root, pattern):
    for path, folders, files in os.walk(root, followlinks=True):
        for fname in files:
            if fnmatch(fname, pattern):
                yield os.path.join(path, fname)


def _collect_filenames_and_labels(cfg):
    path = cfg['input-path']
    pattern = cfg.get('pattern', '*.jpg')
    metadata_file_ext = cfg.get('meta_data_file_ext', '.xml')
    filenames_and_labels = []
    counter = 0
    for fname in find(path, pattern):
        label = os.path.splitext(fname)[0] + metadata_file_ext
        filenames_and_labels.append((fname, label))
        counter += 1
    print 'Images found: ' + `counter`
    return np.array(filenames_and_labels)


def console():
    cfg = get_options(sys.argv[1], 'tag')
    cfg_dataset = get_options(sys.argv[1], 'dataset')
    random_seed(int(cfg.get('seed', '42')))
    collector = resolve(
        cfg.get('collector', 'noccn.tag._collect_filenames_and_labels'))
    filenames_and_labels = collector(cfg)
    creator = resolve(cfg.get('creator', 'noccn.tag.Tagger'))
    create = creator(
        batch_size=int(cfg.get('batch-size', 1000)),
        channels=int(cfg_dataset.get('channels', 3)),
        size=eval(cfg_dataset.get('size', '(64, 64)')),
        model=make_model(TagConvNet,'tag',sys.argv[1]),
        threshold=float(cfg.get('threshold','0.75')),
        tagas=cfg.get('tagas',None)
        )
    create(filenames_and_labels)

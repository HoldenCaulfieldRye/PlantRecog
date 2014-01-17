import cPickle
from fnmatch import fnmatch
import operator
import os
import random
import sys
import traceback

import numpy as np
from PIL import Image
from PIL import ImageOps
from joblib import Parallel
from joblib import delayed

from noccn.script import get_options
from noccn.script import random_seed
from noccn.script import resolve

# This is used to parse the xml files
import xml.etree.ElementTree as ET # can be speeded up using lxml possibly


N_JOBS = -1
SIZE = (64, 64)


def _process_item(creator, name):
    return creator.process_item(name)

def chunks(l, n):
    """ Yield successive n-sized chunks from l.
    """
    for i in xrange(0, len(l), n):
        return_list = l[i:i+n]
        if len(return_list) == n:
            yield return_list

class BatchCreator(object):
    def __init__(self, batch_size=1000, channels=3, size=SIZE,
                 output_path='/tmp', n_jobs=N_JOBS, more_meta=None, **kwargs):
        self.batch_size = batch_size
        self.channels = channels
        self.size = size
        self.output_path = output_path
        self.n_jobs = n_jobs

        if not os.path.exists(output_path):
            os.mkdir(output_path)

        self.more_meta = more_meta or {}
        vars(self).update(**kwargs)  # O_o

    def counter(count):
        print '{0}                                   \r'.format(count),

    def __call__(self, all_names_and_labels, shuffle=False):

	all_ids_and_info = []
	for id, (name, label) in enumerate(all_names_and_labels):
	    all_ids_and_info.append((id, name, label))
	labels_sorted = sorted(set(p[1] for p in all_names_and_labels))

	if shuffle:
	    from sklearn.utils import shuffle as skshuffle
	    names_and_labels, ids_and_names = skshuffle(
		names_and_labels, ids_and_names)

        batch_num = 1
        batch_means = np.zeros((1,self.batch_size))
        for ids_and_info in list(chunks(all_ids_and_info,self.batch_size)):
            print "Generating data_batch_" + `batch_num`
	    rows = Parallel(n_jobs=self.n_jobs)(
		delayed(_process_item)(self, name)
		for a_id, name, label in ids_and_info)
	    names_and_labels = [v for (v, row) in zip(ids_and_info, rows)
				if row is not None]
	    data = np.vstack([r for r in rows if r is not None])
	    labels = [labels_sorted.index(label)
		      for a_id, name, label in ids_and_info]
	    ids = [a_id for (a_id, fname, label) in ids_and_info]
	    data = self.preprocess_data(data)
	    batch = {'data': None, 'labels': [], 'metadata': []}
	    batch['data'] = data.T
	    batch['labels'] = labels
	    batch['ids'] = ids;

            batch_means = np.vstack((batch_means,batch['data'].mean(axis=0)))

	    path = os.path.join(self.output_path, 'data_batch_%s' % batch_num)
	    with open(path, 'wb') as f:
	        cPickle.dump(batch, f, -1)

            batch_num += 1

	batches_meta = {}
	batches_meta['label_names'] = labels_sorted
	batches_meta['metadata'] = dict(
	    (a_id, {'name': name}) for (a_id, name, label) in all_ids_and_info)
        batch_means = np.delete(batch_means,(0),axis=0)
	batches_meta['data_mean'] = batch_means.mean(axis=0)
	batches_meta.update(self.more_meta)
	with open(os.path.join(self.output_path, 'batches.meta'), 'wb') as f:
	    cPickle.dump(batches_meta, f, -1)
        print 'Batch processing complete'

    def load(self, name):
        return Image.open(name)

    def preprocess(self, im):
        """Takes an instance of what self.load returned and returns an
        array.
        """
        im = ImageOps.fit(im, self.size, Image.ANTIALIAS)
        im_data = np.array(im)
        im_data = im_data.T.reshape(self.channels, -1).reshape(-1)
        im_data = im_data.astype(np.single)
        return im_data

    def process_item(self, name):
        try:
            data = self.load(name)
            data = self.preprocess(data)
            return data
        except:
            print "Error processing %s" % name
            traceback.print_exc()
            return None

    def preprocess_data(self, data):
        return data


def find(root, pattern):
    for path, folders, files in os.walk(root, followlinks=True):
        for fname in files:
            if fnmatch(fname, pattern):
                yield os.path.join(path, fname)


def get_info(fname,label_data_fields,metadata_file_ext):
    fname = os.path.splitext(fname)[0] + metadata_file_ext
    tree = ET.parse(fname)
    root = tree.getroot()
    return_dict = {}
    for label_data_field in label_data_fields:
        return_dict[label_data_field] = root.find(label_data_field).text
    # note, much more information exists here and it should be be used, 
    # e.g.multiple shots of the same leaf, type of shot, content of shot
    # as well as the location and the date of the shot
    # this info is accessedd via root.find('Content').text for example
    return return_dict


def _collect_filenames_and_labels(cfg):
    path = cfg['input-path']
    pattern = cfg.get('pattern', '*.jpg')
    metadata_file_ext = cfg.get('meta_data_file_ext', '.xml')
    label_data_field = cfg.get('label_data_field', 'ClassId')
    limit_by_tag = cfg.get('limit_by_tag', 'None')
    filenames_and_labels = []
    counter = 0
    if limit_by_tag == 'None':
        for fname in find(path, pattern):
            label = get_info(fname,[label_data_field],metadata_file_ext)[label_data_field]
            filenames_and_labels.append((fname, label))
            counter += 1
            sys.stdout.write("\rImages found: %d" % counter)
            sys.stdout.flush()
        print '\nNumber of images found: ',
    else:
        limit_to_tag = cfg.get('limit_to_tag', 'None')
        for fname in find(path, pattern):
            info_dict = get_info(fname,[limit_by_tag,label_data_field],metadata_file_ext)
            if info_dict[limit_by_tag]  == limit_to_tag:
                label = info_dict[label_data_field]
                filenames_and_labels.append((fname, label))
                counter += 1
                sys.stdout.write("\rImages found: %d" % counter)
                sys.stdout.flush()
        print '\nNumber of images of type ' + limit_to_tag + ' found: ',
    print len(filenames_and_labels)
    random.shuffle(filenames_and_labels)
    return np.array(filenames_and_labels)


def console():
    cfg = get_options(sys.argv[1], 'dataset')
    random_seed(int(cfg.get('seed', '42')))
    collector = resolve(
        cfg.get('collector', 'noccn.dataset._collect_filenames_and_labels'))
    filenames_and_labels = collector(cfg)
    creator = resolve(cfg.get('creator', 'noccn.dataset.BatchCreator'))
    create = creator(
        batch_size=int(cfg.get('batch-size', 1000)),
        channels=int(cfg.get('channels', 3)),
        size=eval(cfg.get('size', '(64, 64)')),
        output_path=cfg.get('output-path', '/tmp/noccn-dataset'),
        )
    create(filenames_and_labels)

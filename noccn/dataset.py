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

    def counter(message,count):
        print message + '{0}\r'.format(count),

    def dot(self, d='.'):
        sys.stdout.write(d)
        sys.stdout.flush()

    def __call__(self, names_and_labels, shuffle=False):
        batches = []
        ids_and_names = []
        batch_size = self.batch_size

        rows = Parallel(n_jobs=self.n_jobs)(
            delayed(_process_item)(self, name)
            for name, label in names_and_labels
            )

        names_and_labels = [v for (v, row) in zip(names_and_labels, rows)
                            if row is not None]
        for id, (name, label) in enumerate(names_and_labels):
            ids_and_names.append((id, name))
        data = np.vstack([r for r in rows if r is not None])

        if shuffle:
            from sklearn.utils import shuffle as skshuffle
            names_and_labels, ids_and_names, data = skshuffle(
                names_and_labels, ids_and_names, data)

        labels_sorted = sorted(set(p[1] for p in names_and_labels))
        labels = [labels_sorted.index(label)
                  for name, label in names_and_labels]
        ids = [id for (id, fname) in ids_and_names]
        data = self.preprocess_data(data)

        processed = 0
        for batch_start in range(0, len(names_and_labels), batch_size):
            batch = {'data': None, 'labels': [], 'metadata': []}
            batch_end = batch_start + batch_size

            batch['data'] = data[batch_start:batch_end, :].T
            batch['labels'] = labels[batch_start:batch_end]
            batch['ids'] = ids[batch_start:batch_end]
            batches.append(batch)
            processed += 1
            self.counter('Created empty batches: ',processed)
            

        processed = 0
        for i, batch in enumerate(batches):
            path = os.path.join(self.output_path, 'data_batch_%s' % (i + 1))
            with open(path, 'wb') as f:
                cPickle.dump(batch, f, -1)
                processed += 1
                self.counter('Created pickle dump: ',processed)

        batches_meta = {}
        batches_meta['label_names'] = labels_sorted
        batches_meta['metadata'] = dict(
            (id, {'name': name}) for (id, name) in ids_and_names)
        batches_meta['data_mean'] = data.mean(axis=0)
        batches_meta.update(self.more_meta)

        processed = 0
        with open(os.path.join(self.output_path, 'batches.meta'), 'wb') as f:
            cPickle.dump(batches_meta, f, -1)
            self.counter('Created batches.meta: ',processed)

        print
        print "Wrote to %s" % self.output_path

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
            print "Processed %s\r" % name,
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


def get_info(fname,label_data_field,metadata_file_ext):
    fname = os.path.splitext(fname)[0] + metadata_file_ext
    tree = ET.parse(fname)
    root = tree.getroot()
    # note, much more information exists here and it should be be used, 
    # e.g.multiple shots of the same leaf, type of shot, content of shot
    # as well as the location and the date of the shot
    # this info is accessedd via root.find('Content').text for example
    return root.find(label_data_field).text


def _collect_filenames_and_labels(cfg):
    path = cfg['input-path']
    pattern = cfg.get('pattern', '*.jpg')
    metadata_file_ext = cfg.get('meta_data_file_ext', '.xml')
    label_data_field = cfg.get('label_data_field', 'ClassId')
    filenames_and_labels = []
    for fname in find(path, pattern):
        label = get_info(fname,label_data_field,metadata_file_ext)
        filenames_and_labels.append((fname, label))
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

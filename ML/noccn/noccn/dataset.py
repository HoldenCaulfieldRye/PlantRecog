import cPickle
from fnmatch import fnmatch
import operator
import os
import random
import sys
import traceback
import math
import collections

import numpy as np
from PIL import Image
from PIL import ImageOps
from joblib import Parallel
from joblib import delayed

from script import get_options
from script import random_seed
from script import resolve
from ccn import mongoHelperFunctions

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
        self.backup_image = None

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

        batch_num = 1
        number_of_means_to_take = 500
        batches_per_mean_sample = (all_ids_and_info[-1][0]/500)/self.batch_size
        print 'Taking mean every %i batches'%(int(batches_per_mean_sample))
        number_of_means_taken = 0
        batch_means = np.zeros(((self.size[0]**2)*self.channels,1))
        for ids_and_info in list(chunks(all_ids_and_info,self.batch_size)):
            print "Generating data_batch_" + `batch_num`
            rows = Parallel(n_jobs=self.n_jobs)(
                            delayed(_process_item)(self, name)
                            for a_id, name, label in ids_and_info)
            data = np.vstack([r for r in rows if r is not None])
            data = self.preprocess_data(data)
            batch = {'data': None, 'labels': [], 'metadata': []}
            batch['data'] = data.T
            batch['labels'] = np.array([labels_sorted.index(label) for ((a_id, name, label), row) 
                                    in zip(ids_and_info, rows) if row is not None]).reshape((1,self.batch_size))

            if batch_num > (number_of_means_taken*batches_per_mean_sample):
                print 'Taking mean of batch'
                batch_means = np.hstack((batch_means,batch['data'].mean(axis=1).reshape(-1,1)))
                number_of_means_taken += 1
            path = os.path.join(self.output_path, 'data_batch_%s' % batch_num)
            with open(path, 'wb') as f:
                cPickle.dump(batch, f, -1)
                batch_num += 1
                f.close()

        batches_meta = {}
        batches_meta['label_names'] = labels_sorted
        batches_meta['metadata'] = dict(
            (a_id, {'name': name}) for (a_id, name, label) in all_ids_and_info)
        batch_means = np.delete(batch_means,(0),axis=1)
        batches_meta['data_mean'] = batch_means.mean(axis=1).reshape(-1,1)
        batches_meta.update(self.more_meta)
        with open(os.path.join(self.output_path, 'batches.meta'), 'wb') as f:
            cPickle.dump(batches_meta, f, -1)
            print 'Batch processing complete'
            f.close()

    def load(self, name):
        return Image.open(name).convert("RGB")

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
            if self.backup_image is None:
                self.backup_image = np.array(data)
            return data
        except:
            print "Error processing %s using backup filler" % name
            return self.backup_image

    def preprocess_data(self, data):
        return data

    def transform_image_into_many_of_size(im, size):
        ims = []
        # Get current and desired ratio for the images
        im_ratio = im.size[0] / float(im.size[1])
        ratio = size[0] / float(size[1])
        # The image is scaled/cropped vertically or horizontally depending on the ratio
        if ratio > im_ratio:
            im = im.resize((size[0], size[0] * im.size[1] / im.size[0]), Image.ANTIALIAS)
            sub_crops = math.ceil(im.size[1]/im.size[0])
            # And divide it into its subgroups
            for base in xrange(0,im.size[1]-size[1]+1,int((im.size[1]-size[1]+1)/sub_crops)):
                box = (0,base,size[0],base+size[1])
                ims.append(im.crop(box))
        elif ratio < im_ratio:
            im = im.resize((size[1] * im.size[0] / im.size[1], size[1]), Image.ANTIALIAS)
            sub_crops = math.ceil(im.size[0]/im.size[1])
            # And divide it into its subgroups
            for base in xrange(0,im.size[0]-size[0]+1,int((im.size[0]-size[0]+1)/sub_crops)):
                box = (base,0,base+size[0],size[1])
                ims.append(im.crop(box))
        else:
            im = im.resize((size[0], size[1]), Image.ANTIALIAS)
            ims.append(im)
        return ims 

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
        exclude = cfg.get('exclude', 'None')
        for fname in find(path, pattern):
            info_dict = get_info(fname,[limit_by_tag,label_data_field],metadata_file_ext)
            # This is to check whether it has an exclude set
            if (limit_to_tag!='None' and info_dict[limit_by_tag]==limit_to_tag) or (exclude!='None' and info_dict[limit_by_tag]!=exclude) or (limit_to_tag == 'None' and exclude == 'None'):
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
    if int(cfg.get('xml_query',1)) is not 0:
        random_seed(int(cfg.get('seed', '42')))
        collector = resolve(
            cfg.get('collector', 'noccn.dataset._collect_filenames_and_labels'))
        filenames_and_labels = collector(cfg)
    else:
        images, labels = mongoHelperFunctions.bucketing(
                        threshold=int(cfg.get('class_image_thres',1000)),
                        component=cfg.get('limit_by_component',None),
                        componentProb=cfg.get('component_prob_thres',0.0),
                        )
        output_path=cfg.get('output-path', '/tmp/noccn-dataset')
        c = collections.Counter(labels)
        stats_file = open(os.path.join(output_path, 'batch_stats.txt'), 'wb')
        stats_file.write(str(c))
        stats_file.write('\n')
        stats_file.write('Number of label classes: %i \n'%(len(set(labels))))
        stats_file.write('Number of images: %i \n'%(len(images)))
        stats_file.write('Number of labels: %i'%(len(labels)))
        stats_file.close()
        filenames_and_labels = zip(images,labels)
        random.shuffle(filenames_and_labels)
    creator = resolve(cfg.get('creator', 'noccn.dataset.BatchCreator'))
    create = creator(
        batch_size=int(cfg.get('batch-size', 1000)),
        channels=int(cfg.get('channels', 3)),
        size=eval(cfg.get('size', '(64, 64)')),
        output_path=cfg.get('output-path', '/tmp/noccn-dataset'),
        )
    create(filenames_and_labels)


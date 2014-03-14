import os, sys, shutil
import cPickle as pickle
import numpy as np
from PIL import Image

sys.path.append('../../noccn/noccn/')
import datasetNoMongo as dataset

if __name__ == '__main__':
    # get image location
    try: directory = sys.argv[1]
    except: directory = 'test_data/'
    try: img_filename = sys.argv[2]
    except: img_filename = '11.jpg'

    # get numpy array of image
    BC = dataset.BatchCreator
    img_jpg = BC.load(BC, directory+img_filename)
    img_np = BC.preprocess(img_jpg)

    # get label, metadata (hacky)
    os.chdir('test_data/example_ensemble/Two/')
    meta = pickle.load(open('batches.meta'))
    batch = pickle.load(open('data_batch_1'))
    # make data_mean zero because we don't want to demean 1-img data
    meta['data_mean'] = np.zeros(img_np.shape, dtype=np.float32)
    batch['labels'] = np.array([[1]]) # too many brackets?
    batch['data'] = img_np
    

    os.chdir('../')
    if not os.path.isdir('Alex'): os.mkdir('Alex')
    os.chdir('Alex/')

    # pickle dat shit
    pickle.dump(batch, open('data_batch_1', 'wb'))
    pickle.dump(meta, open('batches.meta', 'wb'))
    print '1-img batch stored in:\n', os.getcwd()
    print 'you can pass this directory to plantdataprovider to test it'
    os.chdir('../../../')



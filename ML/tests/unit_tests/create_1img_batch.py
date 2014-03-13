if __name__ == '__main__':

    import os, sys, shutil
    import cPickle as pickle
    import numpy as np
    from PIL import Image

    # get pickled objects
    os.chdir('test_data/example_ensemble/One/')
    pickle_label = open('batches.meta')
    pickle_imgs = open('data_batch_2')

    # unpickle
    meta = pickle.load(pickle_label)
    batch = pickle.load(pickle_imgs)

    # unflatten
    batch['data'] = batch['data'].reshape(3, 256, 256, batch['data'].shape[1])
    batch['data'] = np.require(batch['data'], dtype=np.uint8, requirements='W')

    # get first image, save it, to know what original looks like
    orig_img_np = batch['data'][0].copy() # is this image demeaned?
    orig_img_jpg = Image.fromarray(orig_img_np)
    os.chdir('../')
    try:
        os.mkdir('Alex')
    except:
        shutil.rmtree('Alex/')
        os.mkdir('Alex')
    os.chdir('Alex/')
    orig_img_jpg.save('img.jpg') # saving jpg

    # pickle 1 image batch, save it
    batch['data'] = batch['data'][0].copy()
    batch['labels'] = batch['labels'][0].copy()
    pickle.dump(batch['data'], open('data_batch_1', 'wb'))
    pickle.dump(batch['labels'], open('batches.meta', 'wb'))



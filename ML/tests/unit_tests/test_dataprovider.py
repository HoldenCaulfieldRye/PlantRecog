import unittest
import shutil
import os
from PIL import Image
import numpy as np
import sys

sys.path.append(os.getcwd()+'/../../cuda_convnet/')
import plantdataproviders


class DataProviderTests(unittest.TestCase):
    
    def test_get_next_batch(self):
        D = plantdataproviders.AugmentLeafDataProvider(os.getcwd()+'/test_data/example_ensemble/Two')
        Epoch, Batchnum, Cropped, Labels = [], [], [], []
        # make sure prelim stuff ok
        
        # testing over 100 batches - cannot have this as method arg?
        for count in range(100):
            print 'another batch..'
            epoch, batchnum, [cropped, labels] = D.get_next_batch()
            Epoch.append(epoch)
            Batchnum.append(batchnum)
            Cropped.append(cropped)
            Labels.append(labels)
            cropped = self.unflatten(cropped)
            self.assertEqual(count, epoch)
            self.assertEqual(count, batchnum)
            
        # self.test_crop_size()
        # self.test_forward_increment()
        # self.test_downward_increment()
        # self.test_flip()
            # test_crop_size: assert images are 224x224
            # test_forward_increment: assert pixel 0,0 of 1st img is same as pixel 0,1 in 1st img 2 batches down; do this for 1st 64(?) batches
            # test_downward_increment: assert pixel 0,0 of 1st image is same as pixel 1,0 in 1st img 64 (65?) batches down
            # test_flip: assert pixel 0,0 of 1st image is same as pixel 0,224 in 1st img one batch down; do this for first 10 batches

    def test_crop_size(self):
        """assert images are 224x224. """
        
    def test_forward_increment(self):
        """assert pixel 0,0 of 1st img is same as pixel 0,1 in 
           1st image two batches down."""
        
    def test_downward_increment(self):
        """assert pixel 0,0 of 1st image is same as pixel 1,0 
           in 1st img 64 (65?) batches down."""

    def test_flip(self):
        """assert pixel 0,0 of 1st image is same as pixel 0,224 
           in 1st img one batch down."""

    def unflatten(self, dataProv, cropped):
        cropped += dataProv.data_mean
        cropped = cropped.reshape(3, 224, 224, cropped.shape[1])
        cropped = np.require(cropped, dtype=np.uint8, requirements='W')
        return cropped
        
    # parameterise number of batches and number of images per batch?
    def set_up_dummy_batches(self, batch_dir='../tests/unit_tests/'):
        os.chdir(batch_dir)
        try:
            os.mkdir('DataTest')
        except:
            shutil.rmtree('DataTest')
            os.mkdir('DataTest')
        os.chdir('DataTest')
        print 'created DataTest dir here:', os.getcwd()

        return_dir = os.getcwd()
        valid_prefix = 'data_batch_'

        # create dummy images         
        filename = ''
        # create 6 different images
        testImgs = create_images_to_test_patching(6, 256, 224)

        # create 10 batches
        for i in range(10): 
            os.mkdir(valid_prefix+`i`)
            os.chdir(valid_prefix+`i`)
            # batchSize==5, should have as script arg instead?
            j = 0
            for img_np in testImgs:
                j += 1
                img_file = Image.fromarray(img_np)
                img_file.save('img_'+`j`+'.jpg')
            os.chdir('../')

        # create dummy batch metadata
        shutil.copyfile('../test_data/example_ensemble/One/batches.meta', 'batches.meta')
        return return_dir
    
    def create_images_to_test_patching(self, amount, img_size=256, patch_size=224, path_to_save_dir=''):
        imgArray = []
        num_cases = amount / 3
        whiteImg = np.zeros((img_size, img_size, 3), dtype=np.uint8)
        whiteImg[:,:,:] = 255
        for case in range(num_cases):
            for rgb_value in range(3):
                nextImg = np.copy(whiteImg)
                # print 'moving on to %i-th image' % (len(imgArray))
                # print 'case: %i, num_cases:%i' % (case, num_cases)
                # print 'assigning %i to the %i-th rgb channel to patch starting from %i,%i'
                # % ((case+1) * 100 / num_cases, rgb_value,img_size-patch_size,img_size-patch_size)
                nextImg[img_size-patch_size:,
                               img_size-patch_size:,
                               rgb_value] = (case+1) * 100 / num_cases
                imgArray.append(nextImg)

        if path_to_save_dir != '':
            try:
                os.mkdir('ImgTest')
            except:
                shutil.rmtree('ImgTest')
                os.mkdir('ImgTest')
                os.chdir('ImgTest/')
            for img in imgArray:
                i += 1
                img_jpg = Image.fromarray(img)
                img_jpg.save('patch_test_'+`i`+'.jpg')

        return imgArray

    # export crops like a 3rd world country
    def export_crops_to_jpg(self, dataProv, directory, num_batches):
        try:
            os.mkdir(directory)
        except:
            shutil.rmtree(directory)
            os.mkdir(directory)
        os.chdir(directory)

        for count in range(num_batches):
            epoch, batchnum, [cropped, labels] = dataProv.get_next_batch()

            if epoch > 1:
                print 'epoch 2 reached, no use getting more batches, terminating jpg export'
                return 

            # unflattens array, gives it back its mean, converts into jpg writable
            cropped += dataProv.data_mean
            cropped = cropped.reshape(3, 224, 224, cropped.shape[1])
            cropped = np.require(cropped, dtype=np.uint8, requirements='W')

            os.mkdir('cropped_batch_'+`count`)
            os.chdir('cropped_batch_'+`count`)

            for crop_img_idx in range(cropped.shape[0]):
                crop_img = Image.fromarray(cropped[crop_img_idx,:,:,:])
                crop_img.save('crop_'+`crop_img_idx`+'.jpg')
            os.chdir('../')



# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def main():
    unittest.main()

if __name__ == '__main__':
    main()


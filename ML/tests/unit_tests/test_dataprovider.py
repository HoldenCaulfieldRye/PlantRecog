import unittest
import shutil
import os
from PIL import Image, ImageOps
import numpy as np
import sys

sys.path.append(os.getcwd()+'/../../cuda_convnet/')
import plantdataproviders

data_dir = 'Alex/'


def get_array(image, size):
    im = Image.open(image)
    im = ImageOps.fit(im, size, Image.ANTIALIAS)
    im_data = np.array(im)
    im_data = im_data.T.reshape(3, -1).reshape(-1)
    im_data = im_data.astype(np.single)
    return im_data

pca_data = get_array(os.getcwd()+'/../../cuda_convnet/test.JPG', (256,256))
for i in range(0,7):
    pca_data = np.vstack((pca_data,pca_data))
pca_data = pca_data.T


class DataProviderTests(unittest.TestCase):
    def test_init(self):
        D = plantdataproviders.AugmentLeafDataProvider(os.getcwd()+'/'+data_dir)
        self.assertEqual(3, D.num_colors)
        self.assertEqual([0,0,0], D.patch_idx)
        self.assertEqual(224, D.inner_size)
        self.assertEqual(16, D.border_size)
        self.assertEqual(False, D.multiview)
        self.assertEqual(10, D.num_views)
        self.assertEqual(1, D.data_mult)
        self.assertEqual(3, D.num_colors)
    
    def test_get_next_batch(self):
        D = plantdataproviders.AugmentLeafDataProvider(os.getcwd()+'/'+data_dir)
        epoch, batchnum, Cropped, labels = 0, 0, [], []
        count = 0
        rows_visited = 0
        while epoch<2:
            count += 1
            # can increment forwards 33 times, and flip once every time, so should
            # increment down every 66 iterations
            if count % 66 == 0:
                self.assertEqual(D.patch_idx[1:],[D.border_size*2,1])
                self.assertEqual((D.patch_idx[0]+1)*66, count)
                print 'row, col, flip = ', D.patch_idx
                print 'count, epoch, batchnum: %i, %i, %i' % (count, epoch, batchnum)
                rows_visited += 1
            epoch, batchnum, [cropped, labels] = D.get_next_batch()
            if count == 1:
                self.assertEqual(1, epoch)
                self.assertEqual(1, batchnum)
                self.assertEqual([[1]], labels)
            # print 'cropped shape:', cropped.shape
            Cropped.append(cropped)
            # print 'count, epoch, batchnum: %i , %i, %i' % (count, epoch, batchnum)

        print 'patches have visited %i rows' % rows_visited
        self.assertEqual(rows_visited,(D.border_size*2)+1)     
        expected_dimensions = (D.inner_size*D.inner_size*D.num_colors, 1)
        self.assertEqual(cropped.shape, expected_dimensions)
        self.export_some_images(Cropped, D, data_dir)
         
    def test_get_data_dims(self):        
        D = plantdataproviders.AugmentLeafDataProvider(os.getcwd()+'/'+data_dir)
        epoch, batchnum, [cropped, labels] = D.get_next_batch()
        self.assertEqual(D.get_data_dims(), 224*224*3)

    # def verify_crop_size(self, data_dimensions, expected_dimensions):
    #     """assert images are 224x224xRGB. """
    #     self.assertEqual(data_dimensions, expected_dimensions)
        
    # def verify_forward_increment(self, column_flip, twice_border_size_plus_one_1):
    #     """if forward increment works well, then seeing as there are (border_size*2)+1
    #        steps to increment sideways, and every time we can also flip, then after
    #        every 2*((border_size*2)+1) get_next_batch iterations, patch pixel 0,0 should
    #        have traversed (border_size*2)+1==33 columns ie be on column 32, with flip
    #        activated. We can simultaneously check that patch_idx gets correctly updated
    #        by making this test every 2*((border_size*2)+1)==66 iterations."""
    #     self.assertEqual(column_flip, twice_border_size_plus_one_1)
        
    # def verify_downward_increment(self,rows_visited,twice_border_size_plus_one):
    #     """If downward increment works well, then just after an epoch has ended,
    #        number of rows in original image visited by pixel 0,0 of the patch
    #        should be (border_size*2)+1"""
    #     self.assertEqual(rows_visited,twice_border_size_plus_one)

    def export_some_images(self, Cropped, dataProv, img_dir):
        try:
            os.mkdir(img_dir+'updown')
            os.mkdir(img_dir+'leftright')
            os.mkdir(img_dir+'flip')
        except:
            shutil.rmtree(img_dir+'updown')
            shutil.rmtree(img_dir+'leftright')
            shutil.rmtree(img_dir+'flip')
            os.mkdir(img_dir+'updown')
            os.mkdir(img_dir+'leftright')
            os.mkdir(img_dir+'flip')
        for i in range(len(Cropped)):
            # print 'img_np received has shape:', Cropped[i].shape
            # Cropped[i] += dataProv.data_mean
            Cropped[i] = Cropped[i].reshape(224, 224, 3)
            Cropped[i] = np.require(Cropped[i], dtype=np.uint8, requirements='W')
            # print 'but now has shape:', Cropped[i].shape
            orig_img_np = Cropped[i].copy() # is this image demeaned?
            if i % 32 == 0: (Image.fromarray(orig_img_np)).save(img_dir+'/updown/img_'+`i`+'.jpeg')
            if i <= 64 and i % 2 == 0: (Image.fromarray(orig_img_np)).save(img_dir+'/leftright/img_'+`i`+'.jpeg')
            if i <= 4: (Image.fromarray(orig_img_np)).save(img_dir+'/flip/img_'+`i`+'.jpeg')
                
        
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


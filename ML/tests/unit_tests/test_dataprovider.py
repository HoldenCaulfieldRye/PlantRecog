import shutil
import os
from PIL import Image
import numpy as np
import sys
sys.path.append(os.getcwd()+'/../../cuda_convnet/')
import convdata

# parameterise number of batches and number of images per batch?
def set_up_dummy_batches(batch_dir='../tests/'):
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
    testImgs, control = create_images_to_test_patching(6, 256, 224)
    # for img_np in testImgs:
    #     print 'image received:', img_np
    
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
    return return_dir


def create_images_to_test_patching(amount, img_size=256, patch_size=224, path_to_save_dir=''):
    imgArray = []
    control = []
    num_cases = amount / 3
    whiteImg = np.zeros((img_size, img_size, 3), dtype=np.uint8)
    whiteImg[:,:,:] = 255
    for case in range(num_cases):
        for rgb_value in range(3):
            nextImg = np.copy(whiteImg)
            # print 'moving on to %i-th image' % (len(imgArray))
            # print 'case: %i, num_cases:%i' % (case, num_cases)
            # print 'assigning %i to the %i-th rgb channel to patch starting from %i,%i' % ((case+1) * 100 / num_cases, rgb_value,img_size-patch_size,img_size-patch_size)
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

    return imgArray, control


if __name__ == "__main__":
    os.chdir('../../cuda_convnet/')

    testdir = set_up_dummy_batches()

    D = convdata.AugmentLeafDataProvider(testdir)
    # sort out data_dic['labels']!!
    epoch, batchnum, [cropped, self.data_dic['labels']] = D.get_next_batch() 
    
    # delete dummy batches
    # shutil.rmtree(testdir)




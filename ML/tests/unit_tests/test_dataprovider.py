import shutil
import os
from PIL import Image
import numpy as np
import sys
sys.path.append(os.getcwd()+'/../../cuda_convnet/')
import convdata

# parameterise number of batches and number of images per batch?
def set_up_dummy_batches(batch_dir='../tests/unit_tests/'):
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


def create_images_to_test_patching(amount, img_size=256, patch_size=224, path_to_save_dir=''):
    imgArray = []
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

    return imgArray


def export_crops_to_jpg(dataProv, directory, num_batches):
    for count in range(num_batches):
        epoch, batchnum, [cropped, labels] = dataProv.get_next_batch()

        if epoch > 1:
            print 'epoch 2 reached, no use getting more batches, terminating jpg export'
            return 

        # unflattens array, gives it back its mean, converts into jpg writable
        cropped += dataProv.data_mean
        cropped = cropped.reshape(3, 224, 224, cropped.shape[1])
        cropped = np.require(cropped, dtype=np.uint8, requirements='W')

        # print os.getcwd()
        # os.chdir(directory)
        try:
            os.mkdir('cropped_batch_'+`count`)
        except:
            shutil.rmtree('cropped_batch_'+`count`)
            os.mkdir('cropped_batch_'+`count`)
        os.chdir('cropped_batch_'+`count`)

        for crop_img_idx in range(cropped.shape[0]):
            crop_img = Image.fromarray(cropped[crop_img_idx,:,:,:])
            crop_img.save('crop_'+`crop_img_idx`+'.jpg')
        os.chdir('../')


    

if __name__ == "__main__":
    # os.chdir('../../cuda_convnet/')
    # testdir = set_up_dummy_batches()

    D = convdata.AugmentLeafDataProvider('/home/alex/Git/group-project-master/ML/tests/unit_tests/test_data/example_ensemble/One')
    export_crops_to_jpg(D, 'DataTest/Crop', 100)

    
    # delete dummy batches
    # shutil.rmtree(testdir)




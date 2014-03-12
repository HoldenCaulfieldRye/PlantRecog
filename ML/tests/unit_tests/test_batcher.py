import unittest
import os, sys
import cPickle as pickle
import libs 


HERE = os.path.abspath(os.path.dirname(__file__))+'/'

def get_dict(filepath):
    data = open(HERE+filepath,'rb')
    a_dict = pickle.load(data)
    data.close()
    return a_dict


class BatcherTests(unittest.TestCase):


    def test_stats(self):
        libs.dataset.write_stats_to_file(HERE+'/test_data',['TestOne', 'TestTwo'])
        self.assertTrue(os.path.exists(HERE+'/test_data/batch_stats.txt'))


    def test_console_run(self):                             
        if os.path.exists(HERE+'/test_data/example_ensemble/super_set.meta'):
            os.remove(HERE+'/test_data/example_ensemble/super_set.meta')
        if os.path.exists(HERE+'/test_data/example_ensemble/One/batches.meta'):
            os.remove(HERE+'/test_data/example_ensemble/One/batches.meta')
        if os.path.exists(HERE+'/test_data/example_ensemble/Two/batches.meta'):
            os.remove(HERE+'/test_data/example_ensemble/Two/batches.meta')
        sys.argv = ['dataset.py',HERE+'/test_data/example_ensemble/One/options.cfg']
        libs.dataset.console()    
        sys.argv = ['dataset.py',HERE+'/test_data/example_ensemble/Two/options.cfg']
        libs.dataset.console()    
        self.assertTrue(os.path.exists(HERE+'/test_data/example_ensemble/Two/batches.meta'))
        self.assertTrue(os.path.exists(HERE+'/test_data/example_ensemble/One/batches.meta'))
        self.assertTrue(os.path.exists(HERE+'/test_data/example_ensemble/super_set.meta'))
        super_dict = get_dict('/test_data/example_ensemble/super_set.meta')
        one_dict = get_dict('/test_data/example_ensemble/One/batches.meta')
        two_dict = get_dict('/test_data/example_ensemble/Two/batches.meta')
        self.assertListEqual(one_dict['label_names'],super_dict['labels']['flower'])
        self.assertListEqual(two_dict['label_names'],super_dict['labels']['leaf'])


# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def main():
    unittest.main()

if __name__ == '__main__':
    main()

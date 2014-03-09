import unittest
import os, sys
import cPickle as pickle
import libs 
import numpy as np


HERE = os.path.abspath(os.path.dirname(__file__))+'/'


class CombineTests(unittest.TestCase):


    def test_without_params(self):
        with self.assertRaises(SystemExit):
            sys.argv = ['combine.py','rando',HERE+'test_data/11.jpg']
            libs.combine.console(HERE+'test_data/run.cfg')


    def test_with_invalid_params(self):
        with self.assertRaises(SystemExit):
            sys.argv = ['combine.py']
            libs.combine.console(HERE+'test_data/run.cfg')
            your_method()


    def test_with_super(self):
        super_set_file = {'labels':{'super_labels':['apple','banana','carrot','grape','kra','zea'],
                                    'ConvNet1':['banana','grape','zea'],
                                    'ConvNet2':['apple','kra'],
                                    'ConvNet3':['apple','banana','carrot','grape','kra','zea']},
                          'insert_list':{
                                    'ConvNet1':[0,1,2],
                                    'ConvNet2':[1,1,1,2],
                                    'ConvNet3':[]}}
        super_meta_file = open(HERE+'test_data/super.pickle','wb')
        pickle.dump(super_set_file,super_meta_file)
        super_meta_file.close()
        conv1_arr = np.array([0.8,0.1,0.1])
        conv1 = open(HERE+'test_data/conv1.pickle','wb')
        pickle.dump(conv1_arr,conv1)
        conv1.close()
        conv2_arr = np.array([0.3,0.7])
        conv2 = open(HERE+'test_data/conv2.pickle','wb')
        pickle.dump(conv2_arr,conv2)
        conv2.close()
        conv3_arr = np.array([0.2,0.3,0.1,0.1,0.2,0.1])
        conv3 = open(HERE+'test_data/conv3.pickle','wb')
        pickle.dump(conv3_arr,conv3)
        conv3.close()
        combiner = libs.combine.Combiner(num_results=6,
                error_rates = {'ConvNet1':0.4,'ConvNet2':0.5,'ConvNet3':0.3},
                super_set_file = HERE+'test_data/super.pickle')
        result = combiner({ 'ConvNet1':HERE+'test_data/conv1.pickle', 
                   'ConvNet2':HERE+'test_data/conv2.pickle', 
                   'ConvNet3':HERE+'test_data/conv3.pickle'})
        self.assertEqual(result.shape[0],6)




    def test_without_via_console(self):    
        sys.argv = ['combine.py','leaf',HERE+'test_data/11.jpg','flower',HERE+'test_data/12.jpg']
        libs.combine.console(HERE+'test_data/run.cfg')




# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def main():
    unittest.main()

if __name__ == '__main__':
    main()

import unittest
import os, sys
import cPickle as pickle
import libs 
import numpy as np


HERE = os.path.abspath(os.path.dirname(__file__))+'/'


class RunTests(unittest.TestCase):


    def test_without_params(self):
        with self.assertRaises(SystemExit):
            sys.argv = ['run.py']
            libs.run.console(HERE+'test_data/run.cfg')


    def test_with_invalid_params(self):
        with self.assertRaises(SystemExit):
            sys.argv = ['run.py','rando',HERE+'test_data/11.jpg']
            libs.run.console(HERE+'test_data/run.cfg')


    def test_chunks(self):
        a_list = ['a','b','c','d','g','b','a','y']
        for items in libs.run.chunks(a_list,2):
            self.assertEqual(len(items),2)
            self.assertIn(items[0],a_list)
            self.assertIn(items[1],a_list)


    def test_with_correct_via_console(self):    
        if os.path.exists(HERE+'test_data/11.pickle'):
            os.remove(HERE+'test_data/11.pickle')
        if os.path.exists(HERE+'test_data/12.pickle'):
            os.remove(HERE+'test_data/12.pickle')
        if os.path.exists(HERE+'test_data/13.pickle'):
            os.remove(HERE+'test_data/13.pickle')
        if os.path.exists(HERE+'test_data/14.pickle'):
            os.remove(HERE+'test_data/14.pickle')
        sys.argv = ['run.py','leaf',HERE+'test_data/11.jpg',HERE+'test_data/12.jpg',HERE+'test_data/13.jpg',HERE+'test_data/14.jpg',HERE+'test_data/15.jpg',HERE+'test_data/16.jpg',HERE+'test_data/17.jpg',HERE+'test_data/18.jpg',HERE+'test_data/19.jpg',HERE+'test_data/22.jpg']
        libs.run.console(HERE+'test_data/run.cfg')
        self.assertTrue(os.path.exists(HERE+'test_data/11.pickle'))
        self.assertTrue(os.path.exists(HERE+'test_data/12.pickle'))
        self.assertTrue(os.path.exists(HERE+'test_data/13.pickle'))
        self.assertTrue(os.path.exists(HERE+'test_data/14.pickle'))

        f = open(HERE+'test_data/11.pickle','rb')
        prb_matrix = pickle.load(f)
        self.assertGreater(np.sum(prb_matrix),0.98)
        self.assertLess(np.sum(prb_matrix),1.02)
        f.close()


# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def main():
    unittest.main()

if __name__ == '__main__':
    main()

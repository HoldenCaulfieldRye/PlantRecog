import unittest
import os, sys
import cPickle as pickle
import libs 


HERE = os.path.abspath(os.path.dirname(__file__))+'/'


class RunTests(unittest.TestCase):


    def test_without_params(self):
        pass


    def test_with_invalid_params(self):
        pass


    def test_with_correct_via_console(self):    
        sys.argv = ['run.py','leaf',HERE+'test_data/11.jpg',HERE+'test_data/12.jpg',HERE+'test_data/13.jpg',HERE+'test_data/14.jpg',HERE+'test_data/15.jpg',HERE+'test_data/16.jpg',HERE+'test_data/17.jpg',HERE+'test_data/18.jpg',HERE+'test_data/19.jpg',HERE+'test_data/22.jpg']
        libs.run.console(HERE+'test_data/run.cfg')




# ------------------------------------------------
# Standard boilerplate for our testing environment
# ------------------------------------------------
def main():
    unittest.main()

if __name__ == '__main__':
    main()

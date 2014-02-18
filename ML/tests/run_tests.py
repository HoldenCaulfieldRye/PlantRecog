#!/usr/bin/python
import sys, os
import ccn_tag

def setup_testing_path():
    ML_ROOT = os.path.join(os.path.dirname(os.path.realpath(__file__)),'..')
    sys.path.insert(0, ML_ROOT)

def main():
    setup_testing_path()
    print 'About to run ccn tag tests'
    ccn_tag.run()
    
if __name__ == '__main__':
    main()


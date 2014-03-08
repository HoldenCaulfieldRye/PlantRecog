#!/usr/bin/python
import sys, os
import unittest
import coverage
import time

# Only include files we have made, not third party software
default_directories = [
'../noccn/noccn/dataset.py',
'../noccn/noccn/tag.py',
'../run.py',
'../combine.py',
'../bucketing/mongoHelperFunctions.py',
'../cuda_convnet/*', # Needs to include our data provider file as separate file
]

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '-coverage':
        if len(sys.argv) > 2:
            cov = coverage.coverage(include=sys.argv[2], branch=True)
        else:
            cov = coverage.coverage(include=default_directories, branch=True)
        cov.start()
    testsuite = unittest.TestLoader().discover('.')
    unittest.TextTestRunner(verbosity=1).run(testsuite)
    if len(sys.argv) > 1 and sys.argv[1] == '-coverage':
        cov.stop()
        cov.save()
        timestr = time.strftime("%d-%m-%Y|%H-%M")
        outfile = open('test_results/'+timestr+'.result','wb')
        cov.report(morfs=None, show_missing=True, ignore_errors=None, file=outfile, omit=None, include=None)
        outfile.close()

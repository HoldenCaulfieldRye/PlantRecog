#!/usr/bin/python
import sys, os, shutil
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
'../cuda_convnet/plantdataproviders.py', # need base class too? ie convdata.py?
]


if __name__ == '__main__':
    store_coverage = False
    verbose = False
    for arg in sys.argv:
        if arg == '-coverage':
            store_coverage = True
            cov = coverage.coverage(include=default_directories, branch=True)
            cov.start()
        if arg == '-verbose':
            verbose = True
    if not verbose:
        f = open(os.devnull, 'w')
        sys.stdout = f
    testsuite = unittest.TestLoader().discover('.')
    unittest.TextTestRunner(verbosity=1).run(testsuite)
    if store_coverage:
        cov.stop()
        cov.save()
        timestr = time.strftime("%d-%m-%Y|%H-%M")
        try:
            os.mkdir('test_results')
        except:
            shutil.rmtree('test_results')
            os.mkdir('test_results')
        outfile = open('test_results/'+timestr+'.result','wb')
        cov.html_report(directory='./test_results/html/')
        cov.report(morfs=None, show_missing=True, ignore_errors=None, file=outfile, omit=None, include=None)
        outfile.close()

================================
CUDA_CONVNET SETUP
================================
More detailed instructions are included in the cuda_convnet directory.  If
operating on a lab machine, and CUDA 5.5 is installed for you system, running
the ./build.sh script should compile a fresh copy.  Note, this script alters
your bash path as wel.


================================
SETTING UP A NETWORK
================================
Unfortunately, it is not possible to store all of the weights required for a
pre-trained network in this repository, as it is just too large. To train your
own network, first setup the noccn scripts

    cd noccn/
    ./setup.sh

Then setup and appropriate config file.  Examples can be seen in models/  



=================================
TESTS
=================================
To run the tests for the entire system cd to the tests supdirectory and run:

    python run_tests.py

Note that these tests MUST be run on a computer with at least a Fermi Generation
GPU, and an instance of a mongoDB server running, from our git repository.
All of the tests are stored in the unit test directory.  To be auto-found and run 
here, they must have the 'test' prefix.  E.g. test_tag.py

The coveragepy is added as a submodule of our git repository, we can edit it, and 
pull the latest copy as we wish, without affecting our own repository.  To run the 
tests for coverage metrics, you must ensure it has been setup for your system:

    //coveragepy git url https://github.com/nedbat/coveragepy.git
    python setup.py install --user

Then to run the tests, and get a coverage reading (both statement and branch metrics), 
for all of the default python directories, run the following:

    python run_tests.py -coverage

To run the coverage metrics only for specific directories run e.g. to run for all of the noccn scripts use:

    python run_tests.py -coverage ../noccn/noccn/*

To run while outputting the results:
    
    python run_tests.py -coverage -verbose    

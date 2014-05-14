================================
CUDA_CONVNET SETUP
================================
More detailed instructions are included in the cuda_convnet directory.  If
operating on a lab machine, and CUDA 5.5 is installed for you system, running
the ./build.sh script should compile a fresh copy.  Note, this script alters
your bash path as well.


================================
SETTING UP A NETWORK
================================
Unfortunately, it is not possible to store all of the weights required for a
pre-trained network in this repository, as it is just too large.

1. To train your
own network, first setup the noccn scripts

    cd noccn/
    ./setup.sh

2. Next, you need your data to be batched in a format that the CUDA
program expects: https://code.google.com/p/cuda-convnet/wiki/Data
You can find batch creators under noccn/noccn/dataset.py
    
3. Then, you need to setup 3 configuration files that configure your neural
network:
options.cfg: the 'root' configuration file that tells the python
training script where to find your training data, the network configuration
files, where to save your neural network as training progresses, etc.
layers.cfg: https://code.google.com/p/cuda-convnet/wiki/LayerParams
params.cfg: https://code.google.com/p/cuda-convnet/wiki/LayerParams
Examples for these configurations can be found in the models/ directory. 

4. You are ready to train a network on your data! To run the training in
background:

        nohup ccn-train path_to_your_config_files/options.cfg > path_where_you_want_to_save_output/outanderr.txt 2>&1 &
    
Throughout training, you will have saves of your current neural network
created in the path you specified in options.cfg.


*. If things go wrong, and you want to redo ./build.sh and recompile ,cd to ML/ and:

        make clean 

	



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

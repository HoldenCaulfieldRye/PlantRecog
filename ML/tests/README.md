All of the tests are stored in the unit test directory.  To be auto-found and run here, they must have the 'test' prefix.  E.g. test_tag.py

To run the tests for the entire system simply run:

    python run_tests.py

The coveragepy is added as a submodule of our git repository, we can edit it, and pull the latest copy as we wish, without affecting our own repository.  To run the tests for coverage metrics, you must ensure it has been setup for your system:

	//coveragepy git url 
	https://github.com/nedbat/coveragepy.git

    python setup.py install --user

Then to run the tests, and get a coverage reading (both statement and branch metrics), for all of the default python directories, run the following:

    python run_tests.py -coverage

To run the coverage metrics only for specific directories run e.g. to run for all of the noccn scripts use:

    python run_tests.py -coverage ../noccn/noccn/*

To run while outputting the results:
    
    python run_tests.py -coverage -verbose    

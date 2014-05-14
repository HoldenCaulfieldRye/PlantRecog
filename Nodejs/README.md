	README.md

================================
INSTALLING DEPENDENCIES
================================
We use Node.js v0.10.* along with npm (node package manager).

Ubuntu (our distribution of choice) contains a very old version of Node.js in its stable repositories. Node.js latest stable can be installed on Ubuntu either from source or via apt. Here we include instructions to install via the apt package manager.

===============
Install Node.js
===============

1. Add repository:

	sudo add-apt-repository ppa:chris-lea/node.js

2. Update apt cache:

	sudo apt-get update

3. Install node and deps:

	sudo apt-get install python-software-properties python g++ make nodejs

==========================
Install required libraries
==========================

We use npm to manage our dependencies. npm is installed alongside node if installed from the node ppa. 

Within the ./Nodejs folder there is a package.json which ensures that all dependencies can be simply installed.

We store the macros in a makefile for easy deployment.

1. To install all the requirements for running and testing both the Worker and Request server, do the following:

	make dev-install

2. Alternatively, to install just the modules required for running the application server do:

	make install

=========
Run Tests
=========

To test the Worker and Request servers we use Istanbul and Mocha, both of which are installed along as part of the dev-install command.

To run the tests type:

make all_test

It is also possible to run tests for the individual servers using:

make request_test
or
make worker_test


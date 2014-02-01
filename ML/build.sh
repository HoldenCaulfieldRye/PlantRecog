#!/bin/sh

# Copy CUDA SDK to home directory
if [ -d ~/CUDA_SDK ]; then
    rm -r -f "$CUDA_SDK"
fi
mkdir ~/CUDA_SDK
export CUDA_SDK=~/CUDA_SDK
cp -r /usr/local/cuda/gpu_sdk ~/CUDA_SDK/
cp -r /usr/local/cuda/samples ~/CUDA_SDK/


# Add env vars to ~/.bashrc file
if ! grep -q $'export CUDA_BIN=/usr/local/cuda/bin\nexport CUDA_LIB=/usr/local/cuda/lib64\nexport LOCAL_BIN=${HOME}/.local/bin\nexport LD_LIBRARY_PATH=:${CUDA_LIB}:$LD_LIBRARY_PATH\nexport PATH=${CUDA_BIN}:${LOCAL_BIN}:$PATH' ~/.bashrc; then

    if grep -q 'CUDA_BIN' ~/.bashrc || grep -q 'CUDA_LIB' ~/.bashrc || grep -q 'LOCAL_BIN' ~/.bashrc || grep -q 'LD_LIBRARY_PATH' ~/.bashrc || grep -q 'PATH' ~/.bashrc; then
	echo 'Please manually add the following string to your bashrc file:'
	echo $'export CUDA_BIN=/usr/local/cuda/bin\nexport CUDA_LIB=/usr/local/cuda/lib64\nexport LOCAL_BIN=${HOME}/.local/bin\nexport LD_LIBRARY_PATH=:${CUDA_LIB}:$LD_LIBRARY_PATH\nexport PATH=${CUDA_BIN}:${LOCAL_BIN}:$PATH'
	echo 'then run this script again'
	exit
    fi

    echo 'adding environment variables to ~/.bashrc'
    
    echo $'export CUDA_BIN=/usr/local/cuda/bin\nexport CUDA_LIB=/usr/local/cuda/lib64\nexport LOCAL_BIN=${HOME}/.local/bin\nexport LD_LIBRARY_PATH=:${CUDA_LIB}:$LD_LIBRARY_PATH\nexport PATH=${CUDA_BIN}:${LOCAL_BIN}:$PATH' >>~/.bashrc    
fi

# checking whether joblib, scikit-learn libraries installed; if not install them
python checkpylibs.py
if grep -q 'joblib' checkpylibs.txt; then
    echo "Downloading & installing joblib python library..."
    git clone https://github.com/joblib/joblib.git
    cd joblib
    python setup.py install --user
    cd ..
fi
if grep -q 'sklearn' checkpylibs.txt; then
    echo "Downloading & installing scikit-learn (aka sklearn) python library..."
    git clone https://github.com/scikit-learn/scikit-learn.git
    cd scikit-learn
    python setup.py install --user
    cd ..
fi
rm -f checkpylibs.py checkpylibs.txt


# Fill in these environment variables.
# I have tested this code with CUDA 4.0, 4.1, and 4.2. 
# Only use Fermi-generation cards. Older cards won't work.

# If you're not sure what these paths should be, 
# you can use the find command to try to locate them.
# For example, NUMPY_INCLUDE_PATH contains the file
# arrayobject.h. So you can search for it like this:
# 
# find /usr -name arrayobject.h
# 
# (it'll almost certainly be under /usr)

# CUDA toolkit installation directory.
export CUDA_INSTALL_PATH=/usr/local/cuda

# CUDA SDK installation directory.
export CUDA_SDK_PATH=$HOME/CUDA_SDK

# Python include directory. This should contain the file Python.h, among others.
export PYTHON_INCLUDE_PATH=/usr/include/python2.7

# Numpy include directory. This should contain the file arrayobject.h, among others.
export NUMPY_INCLUDE_PATH=/usr/lib/python2.7/dist-packages/numpy/core/include/numpy/

# ATLAS library directory. This should contain the file libcblas.so, among others.
export ATLAS_LIB_PATH=/usr/lib/atlas-base

make $*


# install DNouri's scripts
cd noccn
./setup.sh
cd ..

echo ""
echo ""
echo "Congratulations! The beast of Cuda-Convnet augmented by Daniel Nouri's dropout and user-friendly scripts, as well as John B. McCormac's data-processing scripts are now installed."
echo "To get started, why not have fun training one of the most powerful neural nets in the world to recognise leaf-scan images better than any PlantClef competitor has ever done? Simply run the following command in bash environment:"
echo "ccn-train models/basic_leafscan_network/options.cfg"
echo ""


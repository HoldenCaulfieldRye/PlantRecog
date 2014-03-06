import sys, os
def add_path():
    sys.path.append(os.path.join(os.path.abspath(os.path.dirname(__file__)), "../../cuda_convnet"))
    sys.path.append(os.path.join(os.path.abspath(os.path.dirname(__file__)), "../../noccn/noccn/"))
    sys.path.append(os.path.join(os.path.abspath(os.path.dirname(__file__)), "../../bucketing/"))
    print sys.path
add_path()
import tag
import mongoHelperFunctions

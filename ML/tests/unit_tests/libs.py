import sys, os
def add_path():
    # Note, these are inserted rather than appended so they are always 
    # the files that are tested.  Not copies in /.local or any other
    sys.path.append(os.path.join(os.path.abspath(os.path.dirname(__file__)), "../../cuda_convnet/"))
    sys.path.append(os.path.join(os.path.abspath(os.path.dirname(__file__)), "../../noccn/noccn/"))
    sys.path.append(os.path.join(os.path.abspath(os.path.dirname(__file__)), "../../bucketing/"))
    sys.path.append(os.path.join(os.path.abspath(os.path.dirname(__file__)), "../../"))
add_path()
import tag
import run
import combine
import dataset
import script
import mongoHelperFunctions

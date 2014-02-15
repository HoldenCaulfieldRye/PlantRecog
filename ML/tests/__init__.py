import os
import glob

# This pulls in all of the files within the tests directory
TEST_DIR = os.path.dirname(os.path.realpath(__file__))
__all__ = [os.path.basename(f)[:-3] for f in glob.glob(TEST_DIR+'/*.py')]

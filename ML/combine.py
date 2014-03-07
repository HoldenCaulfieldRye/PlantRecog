import cPickle as pickle
import os
import sys
import traceback
import numpy as np
import ast
from joblib import Parallel
from joblib import delayed

N_JOBS = -1

# Error values returned by the system should something
# go wrong when combining the information
NO_ERROR = 0
FILE_DOES_NOT_EXIST = 1
ERROR_DELETING_FILES = 2
INVALID_COMMAND_ARGS = 3


# Yields chunks of a specified size n of a list until it
# is empty.  Chunks are not guaranteed to be of size n
# if the list is not a multiple of the chunk size
def chunks(l, n):
    for i in xrange(0, len(l), n):
            yield l[i:i+n]


# Accepts image files which have already been processed
# by the run script.  Combines them using a baysian optimal
# classifier into a single result, with 'beLeaf' level 
# associated with each.  The number of results returned
# is determined in the run.cfg file. See the file for
# a full list of parameters.
class Combiner(object):
    def __init__(self, num_results=5, error_rates = None, 
                   super_set_file = None, n_jobs=N_JOBS):
        self.num_results = num_results
        self.n_jobs = n_jobs
        self.error_rates = error_rates
        if super_set_file is not None:
            super_meta = open(super_set_file,'rb')
            super_dict = pickle.load(super_meta)
            self.insert_list = super_dict['insert_list']
            self.labels_list = super_dict['super_labels']
            super_meta.close
        else:
            self.insert_list = None


    # Works on the baysian equation argmax(sum(P(c|h)*P(D|h)*P(h)))
    # Where P(h) is assumed to be equal for all plant classes and
    # P(D|h) is approximated to the error rate of a given classifier
    def __call__(self, results_dict, delete_file = False):
        combined_prob = None
        for key in results_dict:
            try:
                np_file = open(results_dict[key],'rb')
                np_array = pickle.load(np.file)
                np_file.close()
            except:
                sys.exit(FILE_DOES_NOT_EXIST)

            if delete_file:
                try:
                    os.remove(results_dict[key])
                except:
                    sys.exit(ERROR_DELETING_FILES)
            np_array = np.insert(np_array,self.insert_list[key],0) * self.error_rates[key]
            if combined_prob is None:
                combined_prob = np_array
            else:
                combined_prob = np.vstack((combined_prob,np_array))
        # Print out the top results
        combined_prob = np.sum(combined_prob,axis=0)/np.sum(combined_prob)
        top_results = np.argsort(combined_prob,axis=0)[::-1][:self.num_results]
        print '{'
        for result in top_results:
            print '"%s":%.03f,'%(self.labels_list[result],combined_prob[result])
        print '}'


# The console interpreter.  It checks whether the arguments
# are valid, and also parses the configuration files.
def console():
    cfg = get_options(os.path.dirname(os.path.abspath(__file__))+'/run.cfg', 'combine')
    valid_args = cfg.get('valid_args','entire,stem,branch,leaf,fruit,flower').split(',')
    if len(sys.argv) < 3:
        print 'Must give at least one type and image file as arguments'
        sys.exit(INVALID_COMMAND_ARGS)
    classifier_dict = {}
    for type_and_file in chunks(sys.argv[1:],2):
        if type_and_file[0] not in valid_args:
            print 'Type must be one of: [',
            for arg in valid_args:
                print arg + ' ',
            print ']'
            sys.exit(INVALID_COMMAND_ARGS)
        classifier_dict[type_and_file[0]] = type_and_file[1]
    combiner = resolve(cfg.get('creator', 'combine.Combiner'))
    combine = combiner(
            num_results=int(cfg.get('number-of-results',5)),
            error_rates=ast.literal_eval(cfg.get('error_rates','None'))
            super_set_file=(cfg.get('super-meta-data',None)),
            )
    combine(classifier_dict)
    sys.exit(NO_ERROR)


# Boilerplate for running the appropriate function.
if __name__ == "__main__":
    console()

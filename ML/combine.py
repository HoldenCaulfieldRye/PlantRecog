import cPickle
import os
import sys
import traceback

from joblib import Parallel
from joblib import delayed


N_JOBS = -1
SIZE = (256,256) 

# Error consts
NO_ERROR = 0
FILE_DOES_NOT_EXIST = 1
ERROR_DELETING_FILES = 2
ERROR_INVALID_COMMAND_ARGS = 3


class Combiner(object):
    def __init__(self, num_results=5, n_jobs=N_JOBS):
        self.num_results = num_results
        self.n_jobs = n_jobs

    def __call__(self, types_and_filenames):
        batch_num = 1
        batch_means = np.zeros(((self.size[0]**2)*self.channels,1))
        start_time = time.clock()
        for filenames,next_filenames in get_next(list(chunks(filenames,self.batch_size))):
            if batch_num == 1:
                rows = Parallel(n_jobs=self.n_jobs)(
                                delayed(_process_tag_item)(self.size,self.channels,filename)
                                for filename in filenames)
            data = np.vstack([r for r in rows if r is not None]).T
            if data.shape[1] > 5:
                mean = data.mean(axis=1).reshape(((self.size[0]**2)*self.channels,1))
                data = data - mean
            #else:
		    #   mean = self.model.train_data_provider.data_mean
            #   data = data - mean
            self.model.start_predictions(data)
            if next_filenames is not None:
                rows = Parallel(n_jobs=self.n_jobs)(
                    delayed(_process_tag_item)(self.size,self.channels,filename)
		    for filename in next_filenames)
                names = [name for (r,name) in zip(rows,filenames) if r is not None];
            self.model.finish_predictions(names,self.num_results,self.threshold)
            batch_num += 1
        

class PlantConvNet(convnet.ConvNet):
    def __init__(self, op, load_dic, dp_params={}):
        convnet.ConvNet.__init__(self,op,load_dic,dp_params)
        self.softmax_idx = self.get_layer_idx('probs', check_type='softmax')
        self.tag_names = list(self.test_data_provider.batch_meta['label_names'])
        self.b_data = None
        self.b_labels = None
        self.b_preds = None

    def import_model(self):
        self.libmodel = __import__("_ConvNet") 


    def start_predictions(self, data):
        # Run the batch through the model
        self.b_data = np.require(data, requirements='C')
        self.b_labels = np.zeros((1, data.shape[1]), dtype=np.single)
        self.b_preds = np.zeros((data.shape[1], len(self.tag_names)), dtype=np.single)
        self.libmodel.startFeatureWriter([self.b_data, self.b_labels, self.b_preds], self.softmax_idx)


    def finish_predictions(self, filenames, threshold):
        # Finish the batch
	    self.finish_batch()
        for i,(filename,row) in enumerate(zip(filenames,rows)):
            if self.b_preds[i,row.T[0]]:
                print filename + '[',
                for value in row.T:
                    print "[%.06f]"%(self.b_preds[i,value]),
                print "]"


    def finish_predictions_top_num(self, filenames, num_results, threshold):
        # Finish the batch
	    self.finish_batch()
        rows = np.argsort(self.b_preds,axis=1)[:,::-1][:,:num_results] # positions
        for i,(filename,row) in enumerate(zip(filenames,rows)):
            if self.b_preds[i,row.T[0]] >= threshold:
	        print filename + '{',
	        for value in row.T:
	            print "%s:%.03f;"%(self.tag_names[value],self.b_preds[i,value]),
            print "}"# => Actually " + actual_type + " picture of a " + actual_name


    def write_predictions(self):
        pass

    def report(self):
        pass

    @classmethod
    def get_options_parser(cls):
        op = convnet.ConvNet.get_options_parser()
        for option in list(op.options):
            if option not in ('load_file'):
                op.delete_option(option)
        return op


def console():
    cfg = get_options(os.path.dirname(os.path.abspath(__file__))+'/run.cfg', 'combine')
    creator = resolve(cfg.get('creator', 'combine.Combiner'))
    create = creator(
        num_results=int(cfg.get('number-of-results',5)),
        channels=int(cfg_data_options.get('channels', 3)),
        size=eval(cfg_data_options.get('size', '(256, 256)')),
        model=make_model(PlantConvNet,'run',cfg_options_file),
        threshold=float(cfg.get('threshold',0.0)),
        )
    create(sys.argv[2:])


if __name__ == "__main__":
    console()

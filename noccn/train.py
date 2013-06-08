import sys

import numpy as np

from .ccn import convnet
from .script import run_model


class ConvNet(convnet.ConvNet):
    give_up_epochs = 20

    def conditional_save(self):
        """Only save checkpoint if test error is better than
        previously seen.
        """
        train_size = len(self.train_batch_range)
        train_mean = np.array(
            [e[0]['logprob'][0] for e in
             self.train_outputs[-train_size:]]
            ).mean()
        print "Train error last %d batches: %.6f" % (train_size, train_mean)

        best_test_error = None
        if self.has_var('best_test_error'):
            best_test_error = self.get_var('best_test_error')
            best_test_info = self.get_var('best_test_info')
        
        this_test_error = self.test_outputs[-1][0]['logprob'][0]
        if best_test_error is None or this_test_error < best_test_error:
            self.set_var('best_test_error', this_test_error)
            self.set_var('best_test_info', '%d.%d: -%.2f%%' % (
                self.epoch,
                self.batchnum,
                (1 - this_test_error / best_test_error) * 100
                if best_test_error else 0,
                ))
            convnet.ConvNet.conditional_save(self)
        else:
            print "-" * 55
            print "Not saving because %.6f > %.6f (%s)" % (
                this_test_error, best_test_error, best_test_info)
            print ("=" * 55),

            # See if we want to give up:
            best_epoch = int(self.get_var('best_test_info').split('.', 1)[0])
            if best_epoch < self.epoch - self.give_up_epochs:
                print "Giving up..."
                sys.exit(0)

    def start(self):
        if self.test_only:
            self.test_outputs += [self.get_test_error()]
            self.print_test_results()
            sys.exit(0)
        if self.testing_freq == 1:
            self.test_outputs += [self.get_test_error()]
            self.print_test_results()
        self.train()
    

def console():
    run_model(ConvNet, 'train')

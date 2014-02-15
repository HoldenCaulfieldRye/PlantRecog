import time
import sys
import os
import random
from ConfigParser import ConfigParser

def get_options(filename, section):
    parser = ConfigParser()
    parser.read(filename)
    dirname = os.path.abspath(os.path.dirname(filename))
    options = {}
    for key, value in parser.items(section):
        value = value.replace('$HERE', dirname)
        value = value.replace('$HOME', os.path.expanduser('~'))
        options[key] = value
    return options

def random_pick(some_list):
    random.shuffle(some_list)
    random_pick = []
    for item in some_list:
        random_pick.append(random.randint(0,len(some_list)))
    random_probs = []
    for rand in random_pick:
        random_probs.append(float(rand)/sum(random_pick))
    random_probs.sort(reverse=True)
    return zip(some_list,random_probs)

def chunks(l, n):
    """ Yield successive n-sized chunks from l.
    """
    for i in xrange(0, len(l), n):
            yield l[i:i+n]

def console():
    if len(sys.argv) < 3:
        print 'Must give a component type and valid image file as arguments'
        return
    valid_args = ['entire','stem','branch','leaf','fruit','flower']
    if sys.argv[1] not in valid_args:
        print 'First argument must be:',
        for arg in valid_args:
            print '[' + arg + '] ',
        print ''
        return
    cfg = get_options(os.path.dirname(os.path.abspath(__file__))+'/run.cfg', 'run')
    num_results=int(cfg.get('number-of-results',5))
    random_labels = ['Oak','Beech','Lemon tree','Ash','Maple','Pine','Rose','Tulip','Tomato plant','Lavender','Bonsai']
    for images in chunks(sys.argv[2:],128):
	time.sleep(1.8)
        for image in images:
       	    random_result = random_pick(random_labels)
            print image + ' {',
	    for index in range(0,num_results):
                if index < num_results-1:
                    print '%s:%.03f,'%(random_result[index][0],random_result[index][1]),
                else:
                    print '%s:%0.03f }'%(random_result[index][0],random_result[index][1])
            


if __name__ == "__main__":
    console()

import cPickle as pickle
import tree


def mymain():
    myfile = open('taxonomyTree.pickle','rb')
    mytree = pickle.load(myfile)
    for keys in mytree.images:
        print `keys` + ' => images:' + `mytree.images[keys]` + '  all images:' + `mytree.all_images[keys]`
    myfile.close()



mymain()

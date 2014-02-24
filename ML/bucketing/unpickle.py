import cPickle as pickle
import tree


def mymain():
    myfile = open('taxonomyTree.pickle','rb')
    mytree = pickle.load(myfile)
    for keys in mytree.children:
        print `keys` + ' : ' + `mytree.children[keys]`
    myfile.close()



mymain()

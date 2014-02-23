#!/bin/python

from tree import Tree
import urllib2  # the lib that handles the url stuff
import sys
import cPickle as pickle
import os, os.path


def addAllNodes(tree,wnid,directory):
    lines = urllib2.urlopen('http://www.image-net.org/api/text/wordnet.structure.hyponym?wnid='+wnid)
    sub_children = []
    for line in lines:
        line = line.strip('\n\r')
        if line[0] == '-':
            sub_wnid = line[1:]
            sub_children.append(sub_wnid)
            number_of_images = 0
            if (os.path.isdir(directory+'/'+sub_wnid)):
                number_of_images = len([name for name in os.listdir(directory+'/'+sub_wnid) 
                                        if os.path.isfile(directory+'/'+sub_wnid+'/'+name) and name[-5:] == '.JPEG'])
            print 'Images found for %s:%i' % (sub_wnid,number_of_images)
	    tree.addNode(sub_wnid,wnid,number_of_images)
    if sub_children:
        for sub_child in sub_children:
            addAllNodes(tree,sub_child,directory)


def main(arguments):
    if len(arguments) < 3:
        print 'The argument 1 should be a filename to pickle tree contents into.' 
        print 'The argument 2 should be the directory where the images can be found.'
    else:
	imagenet_tree = Tree('Image Net Tree')
        # Add our selected parent nodes
        imagenet_tree.addNode('n00017222'); # Plant flora root node
        imagenet_tree.addNode('n13083586','n00017222'); # Vascular root
        # Add nodes which we need to build the tree for to a dictionary form node:parent
        node_dictionary = { 
		'n13134302':'n13083586', # Vascular child: Bulbous
		'n13121544':'n13083586', # Vascular child: Aquatic
	        'n13121104':'n13083586', # Vascular child: Desert
		'n13103136':'n13083586', # Vascular child: Woody plants
		'n13100677':'n13083586', # Vascular child: Vines
		'n13085113':'n13083586', # Vascular child: Weed
		'n13084184':'n13083586', # Vascular child: Succulent
		'n12205694':'n13083586', # Vascular child: Herb
		'n11552386':'n13083586', # Vascular child: Spermatophyte
		'n11545524':'n13083586', # Vascular child: Pteridophyte
		'n13100156':'n00017222', # House plant root
		'n13083023':'n00017222', # Poisonous root
        }
        for node in node_dictionary:
            print 'Processing %s' % (node)
            number_of_images = 0
            if (os.path.isdir(arguments[2]+'/'+node)):
                number_of_images = len([name for name in os.listdir(arguments[2]+'/'+node) 
                                        if os.path.isfile(arguments[2]+'/'+node+'/'+name) and name[-5:] == '.JPEG'])
            imagenet_tree.addNode(node,node_dictionary[node],number_of_images)
            print 'Images found for %s:%i' % (node,number_of_images)
            addAllNodes(imagenet_tree,node,arguments[2])
        pickled_file = open(arguments[1],'wb')
	pickle.dump(imagenet_tree,pickled_file)


if __name__ == "__main__":
    main(sys.argv)

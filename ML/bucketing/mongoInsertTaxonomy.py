import cPickle as pickle
import tree
import sys
import pymongo
from   pymongo import MongoClient

# extract command line args: host, port and database
usage = "python unpickle.py <MongoDB_Host> <MongoDB_Port> <MongoDB_Database>"

if len(sys.argv) < 4:
	print "ERROR: Insufficient command line arguments supplied"
	print "       usage: '" + usage + "'"
	sys.exit(2)

db_host  = sys.argv[1]
db_port  = int(sys.argv[2])
database = sys.argv[3]

client = MongoClient(db_host, db_port)
db = client[database]
wordnetCollection = db.taxonomy


def mymain():
    #unpickle taxonomy tree
    myfile = open('taxonomyTree.pickle','rb')
    mytree = pickle.load(myfile)
    for keys in mytree.children:
        doc = {"Parent" : keys,        #consider renaming this to "Node"??
               "Children" : mytree.children[keys]
              #"Exclude" : 'false'
        }
        print doc
        post_id = wordnetCollection.insert(doc)
        if post_id is None:
            print "Error posting parent: %s" % (keys) 
            if not client.alive():
                print "Connection to mongodb has gone down!! Please retry"
                sys.exit(2)
    print "Finished inserting taxonomy tree into MongoDB"
    myfile.close()


mymain()

#!/usr/bin/python
'''
	This script generates a taxon tree and bucketing algo based on the logic 
	in 'tree.py'. 
	It then calls a function (insertBucketsIntoMongo) which will parse the 
	resulting algo and insert its contents into a MongoDB collection 

	This scripts expects 3 arguments: mongodb host; mongodb port; mongodb database
	TO-DO: Have the command line arguments parsed from a config file

	example usage: python runBucketing.py localhost 55517 development	

	author: ghaughian (Feb 2014)
'''

import sys
import pymongo
from   pymongo import MongoClient

# load dependent python files
import tree
import mongoInsertBuckets

# extract command line args: host, port and database
usage = "python runBucketing.py <MongoDB_Host> <MongoDB_Port> <MongoDB_Database>"

if len(sys.argv) < 4:
	print "ERROR: Insufficient command line arguments supplied"
	print "       usage: '" + usage + "'"
	sys.exit(2)

db_host  = sys.argv[1]
db_port  = int(sys.argv[2])
database = sys.argv[3]

# sample bucket dictionary for testing
#bucket = {"a":"l", "b":"m", "c":"n", "d":"o", "e":"p"}


# run tree function(s) in order to generate 'bucket' dictionary
# TO-DO: Change tree.py so that a single function call (which we call from this script)
#	 triggers the generation of the taxon tree and bucketing info
#	 It needs to return a reference to a Tree object so that we can extract the 
#	 'bucket' dictionary from it.
from taxonTree import t


# now insert buckets into mongo
client = MongoClient(db_host, db_port)
db = client[database]
bucketCollection = db.buckets

# g1 is the name of an instansiated Tree object returned from the tree.py script
# WARN: this needs to match the tree object returned from the above command 
#	(i.e. when the above TO-DO has been actioned)
bucket  = tree.g1.bucket
mongoInsertBuckets.insertBucketsIntoMongo(bucket, bucketCollection)




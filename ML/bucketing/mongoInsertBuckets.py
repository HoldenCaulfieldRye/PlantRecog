#!/usr/bin/python

import sys
import pymongo
from   pymongo import MongoClient

# Need a way of passing and desierable db host port and db name...from a config file
database = sys.argv[1]
db_host  = sys.argv[2]
db_port  = sys.argv[3]

client = MongoClient(db_host, db_port)

db = client.database
bucketCollection = db.buckets

#bucket is the resulting dict generated in graph.py
species = bucket.keys()

for i in keys 
	doc = { "species" : species[i], 
			"bucket"  : bucket[species[i]] }
	post_id = bucketCollection.insert(doc)
	if post_id is None:
		print "error posting species bucket: %s" % (bucket[species[i]]) 
		if not client.alive():
			print "connection to mongodb has gone down"
			sys.exit(2)

print "Finished inserting bucket data into MongoDB"



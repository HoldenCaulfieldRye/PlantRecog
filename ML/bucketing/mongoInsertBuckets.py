'''
	This function will split up the contents of a 'bucket' dictionary and 
	insert its contents into the 'mongoCollection'. 
	'bucket' must be a dict of the form species -> bucket
	'mongoCollection' should be a connection to a mongo collection

	author: ghaughian (Feb 2014)
'''

def insertBucketsIntoMongo(bucket, mongoCollection):
	species = bucket.keys()
	for plant in species:
		doc = { "species" : plant, 
			"bucket"  : bucket[plant] }
		post_id = mongoCollection.insert(doc)
		if post_id is None:
			print "Error posting species bucket: %s" % (plant) 
			if not client.alive():
				print "Connection to mongodb has gone down!! Please retry"
				sys.exit(2)
	print "Finished inserting bucket data into MongoDB"
	return 



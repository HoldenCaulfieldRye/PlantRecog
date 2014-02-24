import sys
import pymongo
from   pymongo import MongoClient

# extract command line args: host, port and database
usage = "python mongoInsertWordNet.py <MongoDB_Host> <MongoDB_Port> <MongoDB_Database>"

if len(sys.argv) < 4:
	print "ERROR: Insufficient command line arguments supplied"
	print "       usage: '" + usage + "'"
	sys.exit(2)

db_host  = sys.argv[1]
db_port  = int(sys.argv[2])
database = sys.argv[3]

client = MongoClient(db_host, db_port)
db = client[database]
wordnetCollection = db.wordnet

words = open('/homes/gh413/group-project-master/ML/bucketing/words.txt', 'rb')
gloss = open('/homes/gh413/group-project-master/ML/bucketing/gloss.txt', 'rb')

glossID = {}

for line in gloss:
    splitline =  line.strip().split('\t')
    glossID[splitline[0]] = splitline[1] 
gloss.close()

for line in words:
    splitline =  line.strip().split('\t')
    doc = { "wnid" : splitline[0],
            "name" : splitline[1],
            "glossary" : glossID[splitline[0]]}
    print doc
    post_id = wordnetCollection.insert(doc)
    if post_id is None:
        print "Error posting species bucket: %s" % (splitline[0]) 
        if not client.alive():
            print "Connection to mongodb has gone down!! Please retry"
            sys.exit(2)
print "Finished inserting word data into MongoDB"
words.close()



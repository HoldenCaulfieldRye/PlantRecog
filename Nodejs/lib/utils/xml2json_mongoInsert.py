import xmltodict, json
import os.path
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
plantCollection = db.plants

image_data = '/data2/ImageNet/train/'
num_images = 1000000

synsets = open('/homes/gh413/group-project-master/Nodejs/lib/utils/synsets.txt', 'rb')

words = open('/homes/gh413/group-project-master/ML/bucketing/words.txt', 'rb')
gloss = open('/homes/gh413/group-project-master/ML/bucketing/gloss.txt', 'rb')

glossID = {}
wordsID = {}

for line in gloss:
    splitline =  line.strip().split('\t')
    glossID[splitline[0]] = splitline[1] 
gloss.close()

for line in words:
    splitline =  line.strip().split('\t')
    wordsID[splitline[0]] = splitline[1] 
words.close()


for synset in synsets:
    synset = synset.strip()
    for i in range(num_images):
        fname = "%s%s/%s_%s.xml" % (image_data, synset, synset, str(i))
        if os.path.isfile(fname):
            print fname
            data = open(fname, 'rb')
            dict = xmltodict.parse(data)['root']['meta_data']
            dict['Synset_ID'] = synset
            dict['Species'] = wordsID[synset]
            dict['Description'] = glossID[synset]
            doc = json.dumps(dict)
            doc2 = json.loads(doc)
            print doc2
            post_id = plantCollection.insert(doc2)
            if post_id is None:
                print "Error posting species bucket: %s" % (splitline[0]) 
                if not client.alive():
                    print "Connection to mongodb has gone down!! Please retry"
                    sys.exit(2)
print "Finished inserting word data into MongoDB"

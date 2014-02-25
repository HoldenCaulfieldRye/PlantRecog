import xmltodict, json
import os.path
import os
import sys
import pymongo
from   pymongo import MongoClient
#from subprocess import call

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

synset_cmd = 'ls -1 ' + image_data + ' > ./synsets.txt'
os.system(synset_cmd)
synsets = open('./synsets.txt', 'rb')

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
    synset_images_cmd = 'ls -1 ' + image_data + synset + '/ | grep .xml > ./synset_images.txt'
    os.system(synset_images_cmd)
    synset_images = open('./synset_images.txt', 'rb')
    for img in synset_images:
        fname = "%s%s/%s" % (image_data, synset, img.strip())
        data = open(fname, 'rb')
        dict = xmltodict.parse(data)['root']['meta_data']
        dict['Synset_ID'] = synset
        dict['Species'] = wordsID[synset]
        dict['Description'] = glossID[synset]
        dict['Exclude'] = 'false'
        doc = json.loads(json.dumps(dict))
        post_id = plantCollection.insert(doc)
        if post_id is None:
             print "Error posting image meta-data file: %s" % (fname) 
             if not client.alive():
                print "Connection to mongodb has gone down!! Please retry"
                sys.exit(2)
print "Finished inserting image meta-data into MongoDB"





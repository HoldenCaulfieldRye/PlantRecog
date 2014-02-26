'''
Exclude the following (???) :

n11669921 -> flower
n11665372 -> angiosperm, flowering plant
n11552386 -> spermatophyte, phanerogam, seed plant
n13083586 -> tracheophyte, vascular plant
n00017222 -> plant, flora, plant life


'''
import os
import pymongo
from   pymongo import MongoClient

client = MongoClient('localhost', 57027)
db = client['development']

def bucketing(threshold, component, componentProb):
    images = list()
    species = list()
    #exec bucketing.js on mongo instance
    bucket_cmd = "mongo localhost:57027/development --eval \"THRES=" + str(threshold) + ", TAG=\'" + component + "\', PROB=\'" + str(componentProb) + "\';\" bucketing.js"
    print bucket_cmd
    os.system(bucket_cmd)
    res = db.plants.find({ 'Exclude' : False, 'Count' : {'$gte' : threshold}, '$where' : "this.Bucket != this.Synset_ID" } , {'Image':True, 'Species':True , '_id':False})
    print 'number of images returned: ' + str(res.count())
    for i in res:
        images.append(i['Image'])
        species.append(i['Species'])
    return images, species



def exclude_synset(synset):
    res = db.plants.update({'Synset_ID' : synset}, {'$set' : {'Exclue': True}},  {'multi' : True})
    return res


#Example usage:
img, spec = bucketing(500, "Leaf", 0.8)
#print img
#print spec


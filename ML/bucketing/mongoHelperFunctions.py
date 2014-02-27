'''
Exclude the following (???) :

n11669921 -> flower
n11665372 -> angiosperm, flowering plant
n11552386 -> spermatophyte, phanerogam, seed plant
n13083586 -> tracheophyte, vascular plant
n00017222 -> plant, flora, plant life
n11545524 -> nonflowering plant

n13104059 -> tree
n12651821 -> fruit tree

n11645914 -> araucaria
n13109733 -> angiospermous tree


#possibilities???
n13085113 -> weed
n11779300 -> arum (about 25 species of flowering plants in the family Araceae) ?? too general?
n13108662 -> gymnospermous tree (any tree of the division Gymnospermophyta)
n11915214 -> composite plant
n12205694 -> herb, herbaceous plant
n13084184 -> succulent plant
'''


import os
import pymongo
from   pymongo import MongoClient

client = MongoClient('localhost', 57127)
db = client['qa']

def bucketing(threshold, component, componentProb):
    images = list()
    species = list()
    #exec bucketing.js on mongo instance
    bucket_cmd = "mongo localhost:57127/qa --eval \"THRES=" + str(threshold) + ", TAG=\'" + component + "\', PROB=\'" + str(componentProb) + "\';\" bucketing.js"
    print bucket_cmd
    os.system(bucket_cmd)
    #res = db.plants.find({ 'Exclude' : False, 'Count' : {'$gte' : threshold}, '$where' : "this.Bucket != this.Synset_ID" } , {'Image':True, 'Species':True , '_id':False})
    res = db.plants.find({ 'Exclude' : False, 'Count' : {'$gte' : threshold}} , {'Image':True, 'Species':True , '_id':False})
    print 'number of images returned: ' + str(res.count())
    for i in res:
        images.append(i['Image'])
        species.append(i['Species'])
    return images, species



def exclude_synset(synset):
    print "excluding synset " + synset
    res = db.plants.update({'Synset_ID' : synset}, {'$set' : {'Exclude': True}}, False, {'multi' : True})
    return res


#Example usage:
img, spec = bucketing(900, "Leaf", 0.8)
print img
print spec


#exclude_synset("n00017222")



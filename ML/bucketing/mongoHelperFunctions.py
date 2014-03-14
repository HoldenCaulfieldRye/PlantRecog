import os
import pymongo
from   pymongo import MongoClient


# MongoDB connection details
client = MongoClient('localhost', 57127)
db = client['qa']


# a list of valid tag names
valid_tags = [ 'Leaf', 'Fruit', 'Flower', 'Entire', 'Branch', 'Stem' ]



def bucketing(threshold, component=None, componentProb=0.0):
    images = list()
    species = list()
    
    #exec bucketing.js on mongo instance
    path = os.path.join(os.path.abspath(os.path.dirname(__file__)), "../../Nodejs/lib/utils/bucketing.js")
    if component is None:
        bucket_cmd = "mongo localhost:57127/qa --eval \"THRES=" + str(threshold) + ", PROB=\'" + str(componentProb) + "\'\" " + path
    elif component in valid_tags:
        bucket_cmd = "mongo localhost:57127/qa --eval \"THRES=" + str(threshold) + ", TAG=\'" + component + "\', PROB=\'" + str(componentProb) + "\';\" " + path
    else:
        print "ERROR: Invalid Component Tag provided"
        return -1

    print bucket_cmd

    b = os.system(bucket_cmd)
    if b:
         print "ERROR: Bucketing Script returned error code: " + str(b)
         return -2

    buckets = get_buckets(threshold, component, componentProb)

    if component is None:
        res = db.plants.find({'Bucket':{'$in':buckets}, 'Exclude':False, 'Component_Tag_Prob':{'$gte':componentProb}}, {'Image':True, 'BucketSpecies':True , '_id':False})
    else:
        res = db.plants.find({'Bucket':{'$in':buckets}, 'Exclude':False, 'Component_Tag':component, 'Component_Tag_Prob':{'$gte':componentProb}}, {'Image':True, 'BucketSpecies':True , '_id':False})
    print 'number of images returned: ' + str(res.count())
    for i in res:
        images.append(i['Image'])
        species.append(i['BucketSpecies'])
    return images, species



'''
//////////////////////////////////////////////////////////////////
/////////// return a list of synset_ids that have been ///////////
///////////     bucketed based on a given threshold    ///////////
//////////////////////////////////////////////////////////////////
'''
def get_buckets(threshold, component, componentProb):
    results = list()
    exclude_buckets = db.plants.find({'Exclude':True},{'Bucket':True,'_id':False}).distinct('Bucket')
    if component is None:
        pipe = [{'$match':{'Component_Tag_Prob':{'$gte':componentProb}, 'Exclude':False, 'Bucket':{'$nin':exclude_buckets}}}, {'$group':{'_id':"$Bucket", 'count':{'$sum':1}}}]
    else:
        pipe = [{'$match':{'Component_Tag':component, 'Component_Tag_Prob':{'$gte':componentProb}, 'Exclude':False, 'Bucket':{'$nin':exclude_buckets}}}, {'$group':{'_id':"$Bucket", 'count':{'$sum':1}}}]
    res = db.plants.aggregate(pipeline=pipe)
    r_res = res['result']
    results = [r['_id'] for r in r_res if r['count'] >= threshold]
    return results 



'''
///////////////////////////////////////////////////////////////
/////////// "exclude" synsets based on species name ///////////
///////////////////////////////////////////////////////////////
'''
def exclude_synset(name):
    synset = None
    data = db.wordnet.find({'name': name},{'wnid':True, '_id':False})
    for i in data:
        synset = i['wnid']
        print "excluding synset: " + synset
        db.plants.update({'Synset_ID' : synset}, {'$set' : {'Exclude': True}}, multi=True)
    return synset  


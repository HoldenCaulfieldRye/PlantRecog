'''
Exclude the following (???) :

n11669921 -> flower
n11665372 -> angiosperm, flowering plant
n11552386 -> spermatophyte, phanerogam, seed plant
n13083586 -> tracheophyte, vascular plant
n00017222 -> plant, flora, plant life


'''

import pymongo
from   pymongo import MongoClient

client = MongoClient('localhost', '57027')
db = client['development']

def bucketing(threshold, component, componentProb)
    db.eval(bucketing, threshold, component, componentProb)


def exclude_synset(synset)
    db.eval(exclude_synset,synset)


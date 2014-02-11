
######################################################################################
#                                                                                    #
# In this implementation, nodes are not objects, all info is centralised             #
#                                                                                    #
# Must have a directed graph for notion of parenthood in taxon tree (so be careful   #
# with ordering of args in addEdge(parentNode, childNode)                            #
#                                                                                    #
# Bucketing threshold can be specified as arg, default is 1000                       #
#                                                                                    #
# WARNING: If not a tree, image propagation goes wrong (need to improve algo)        #
#          ie if there exists multiple paths from a node to another, image prop goes #
#          wrong                                                                     #
#                                                                                    #
# WARNING: Still need to write another addEdge() for case where ImageNet provides    #
#          propagated images                                                         #
#                                                                                    #
# WARNING: Still need to split 'images' field into 'personalImages' and              #
#          'bucketedImages'; can currently only perform one bucketing per graph      #
#                                                                                    #
# NOTE   : A species/node is either classifiable, unclassifiable, or unnecessary     #
#          (unnecessary when all children are classifiable)                          #
#          so with current implementation, if 1000 labrador images and 50 chiuahuah  #
#          images, then labrador and dog are classifiable, ie it's possible for a    #
#          parent and a child to be classifiable. let me know if you don't want that # 
#                                                                                    #
#                                                                                    #
# NOTE   : Maybe should keep track of which classes have been bucketed into which    #
#          classes? let me know                                                      #
#                                                                                    #
# NOTE   : Maybe should be able to generate graph from an xml file? wait and see     #
#          ImageNet provide                                                          #
#                                                                                    #
######################################################################################

import sys

class Graph:
    def __init__(self,name=""):
        self.name = name      # name of graph
        self.parents = {}     # dict of neighbours: keys are nodeNames, values are lists of nodeNames
        self.children = {}    # same with children
        self.nodeNames = {}   # dict of nodeNames: keys are nodeNames, values are bool
        self.images = {}
        self.unclassifiable = []
        self.classifiable = []
        self.unnecessary = []
        

    def addNode(self,nodeName,numImages=0):
        self.nodeNames[nodeName] = True
        self.images[nodeName] = numImages
        self.children[nodeName] = []
        self.parents[nodeName] = []
        

    def propagateImages(self, nodeName, numImages, parents):

        # print "propagate called with %s, %i, %s" % (nodeName, numImages, parents)
        
        if parents == []: return
        
        for parent in parents:
            try:
                self.images[parent] += numImages
            except:
                self.images[parent] = numImages

            # print "len(%s.parents[%s]) == %i" % (self, parent, len(self.parents[parent]))

            if len(self.parents[parent]) > 0:
                self.propagateImages(parent, numImages, self.parents[parent]) #self.propagateImages? self as arg?
    
        
    def addEdge(self,parentNode,childNode):
        if childNode in self.children[parentNode]:
            print 'edge already exists'
            return
        
        self.children[parentNode].append(childNode)
        self.parents[childNode].append(parentNode)

        # propagate child's images to new parent only, not to all!
        # print '(addEdge): about to propagate', childNode, '\'s', self.images[childNode], 'images to all its ancestors'
        self.propagateImages(childNode, self.images[childNode], [parentNode])

            
    def getChildren(self, nodeName=''):
        # try: 
        if nodeName == '': return self.children
        else: return self.children[nodeName]
        # except: return []


    def getParents(self, nodeName=''):
        # try: 
        if nodeName == '': return self.parents
        else: return self.parents[nodeName]
        # except: return []


    def getImages(self, nodeName=''):
        # try: 
        if nodeName == '': return self.images
        else: return self.images[nodeName]
        # except: return []


    def getNodes(self):
        return self.nodeNames.keys()
    
    def deleteEdge(self,parentNodeName,childNodeName):
        # try :
        self.children[parentNodeName].remove(childNodeName)
        self.parents[childNodeName].remove(parentNodeName)
        # except :
        #     return "error"

    def deleteNode(self,nodeName):
        del self.nodeNames[nodeName]
        # try :
        for otherNodeName in self.children[nodeName] :
            self.children[otherNodeName].remove(nodeName)
        del self.children[nodeName]
        
        for otherNodeName in self.parents[nodeName] :
            self.parents[otherNodeName].remove(nodeName)
        del self.parents[nodeName]
        # except :
        #     return "error"
        
        
    def bucketAlgo(self, threshold=1000):
        for node in self.nodeNames:
            if self.images[node] < threshold:
                self.unclassifiable.append(node)
            else: self.unnecessary.append(node)

        for node in self.unnecessary:
            # try:
            if self.children[node] == []:
                self.unnecessary.remove(node) 
                self.classifiable.append(node)
                continue

            for child in self.children[node]:
                if child in self.unclassifiable:
                    self.unnecessary.remove(node)
                    self.classifiable.append(node)
                    break

            # except: # reach here if node has no children and images >= threshold
            #     self.unnecessary.remove(node) 
            #     self.classifiable.append(node)
                
        print 'total #classes:', len(self.unclassifiable)+len(self.classifiable)+len(self.unnecessary), '(check:', len(self.nodeNames.keys()), ')'
        print '#classifiable:', len(self.classifiable)
        print '#unnecessary:', len(self.unnecessary)
        print '#unclassifiable:', len(self.unclassifiable)

        
    def getBucketResults(self):
        return self.classifiable, self.unnecessary, self.unclassifiable
        


def createNodes(g):
    g.addNode('tree')
    g.addNode('african tree')
    g.addNode('european tree')
    g.addNode('american tree')
    g.addNode('asian tree')


    # typical case 1: sibling nodes all classifiable
    g.addNode('evergreen european tree', 1500)
    g.addNode('palm european tree', 2300)


    # typical case 2: sibling nodes all unclassifiable and parent classifiable
    g.addNode('big american tree', 750)
    g.addNode('small american tree', 800)


    # typical case 3: sibling nodes and parent all unclassifiable
    # note dangling node is a subcase of this, in which there is 'a single sibling node'
    g.addNode('pointy asian tree', 50)
    g.addNode('square asian tree', 34)


    # edge case 1: a classifiable sibling, an unclassifiable sibling
    g.addNode('sexy african tree', 70)
    g.addNode('minger african tree', 1250)


# if __name__ == "__main__":
print 'shh testing, attention please'

######################################################################
#  PART 1: initialise graphs                                         #
######################################################################

g1 = Graph()
g2 = Graph()
g3 = Graph()
g4 = Graph()
g5 = Graph()


######################################################################
#  PART 2: create node-wise identical graphs                         #
######################################################################

createNodes(g1)
createNodes(g2)
createNodes(g3)
createNodes(g4)
createNodes(g5)


######################################################################
#  PART 3: add same edges to each graph, but in different order      #
######################################################################

print 'adding edges'

## CASE 1: add all leaves first, then parents

# add edge involving a leaf
g1.addEdge('european tree', 'evergreen european tree')
g1.addEdge('european tree', 'palm european tree')
g1.addEdge('american tree', 'big american tree')
g1.addEdge('american tree', 'small american tree')
g1.addEdge('asian tree', 'pointy asian tree')
g1.addEdge('asian tree', 'square asian tree')
g1.addEdge('african tree', 'sexy african tree')
g1.addEdge('african tree', 'minger african tree')

# add edge involving parents only
g1.addEdge('tree', 'european tree')
g1.addEdge('tree', 'american tree')
g1.addEdge('tree', 'asian tree')
g1.addEdge('tree', 'african tree')



# CASE 2: add all parents first, then leaves

# add edge involving parents only
g2.addEdge('tree', 'european tree')
g2.addEdge('tree', 'american tree')
g2.addEdge('tree', 'asian tree')
g2.addEdge('tree', 'african tree')

# add edge involving a leaf
g2.addEdge('european tree', 'evergreen european tree')
g2.addEdge('european tree', 'palm european tree')
g2.addEdge('american tree', 'big american tree')
g2.addEdge('american tree', 'small american tree')
g2.addEdge('asian tree', 'pointy asian tree')
g2.addEdge('asian tree', 'square asian tree')
g2.addEdge('african tree', 'sexy african tree')
g2.addEdge('african tree', 'minger african tree')



# CASE 3: mix up leaf/parent adding order

g3.addEdge('european tree', 'palm european tree')
g3.addEdge('tree', 'american tree')
g3.addEdge('american tree', 'big american tree')
g3.addEdge('asian tree', 'pointy asian tree')
g3.addEdge('tree', 'african tree')
g3.addEdge('african tree', 'sexy african tree')
g3.addEdge('african tree', 'minger african tree')
g3.addEdge('asian tree', 'square asian tree')
g3.addEdge('tree', 'european tree')
g3.addEdge('european tree', 'evergreen european tree')
g3.addEdge('tree', 'asian tree')
g3.addEdge('american tree', 'small american tree')



# CASE 4: mix up leaf/parent adding order differently

g4.addEdge('asian tree', 'square asian tree')
g4.addEdge('european tree', 'evergreen european tree')
g4.addEdge('american tree', 'small american tree')
g4.addEdge('tree', 'american tree')
g4.addEdge('african tree', 'sexy african tree')
g4.addEdge('american tree', 'big american tree')
g4.addEdge('tree', 'asian tree')
g4.addEdge('asian tree', 'pointy asian tree')
g4.addEdge('tree', 'african tree')
g4.addEdge('african tree', 'minger african tree')
g4.addEdge('tree', 'european tree')
g4.addEdge('european tree', 'palm european tree')



# CASE 5: mix up leaf/parent adding order again differently

g5.addEdge('asian tree', 'square asian tree')
g5.addEdge('american tree', 'small american tree')
g5.addEdge('tree', 'american tree')
g5.addEdge('african tree', 'minger african tree')
g5.addEdge('european tree', 'evergreen european tree')
g5.addEdge('tree', 'european tree')
g5.addEdge('american tree', 'big american tree')
g5.addEdge('tree', 'asian tree')
g5.addEdge('african tree', 'sexy african tree')
g5.addEdge('asian tree', 'pointy asian tree')
g5.addEdge('european tree', 'palm european tree')
g5.addEdge('tree', 'african tree')


if not g1.images['tree'] == g2.images['tree'] == g3.images['tree'] == g4.images['tree'] == g5.images['tree']:
    print 'PROBLEM!!'
    print "g1.images['tree'] == %i \ng2.images['tree'] == %i \ng3.images['tree'] == %i \ng4.images['tree'] == %i \ng5.images['tree'] == %i \n" % (g1.images['tree'], g2.images['tree'], g3.images['tree'], g4.images['tree'], g5.images['tree'])

else: print 'addEdge() SUCCESS :)'

######################################################################
#  PART 4: bucketing                                                 #
######################################################################

print 'bucketing with threshold at 1000 images'
print 'images for each node:'
print g1.getImages()
g1.bucketAlgo()
print ''
print 'classifiable: %s, \nunnecessary: %s, \nunclassifiable: %s\n' % (g1.getBucketResults()[0], g1.getBucketResults()[1], g1.getBucketResults()[2])

g2.bucketAlgo()
g3.bucketAlgo()
g4.bucketAlgo()
g5.bucketAlgo()

if not g1.getBucketResults() == g2.getBucketResults() == g3.getBucketResults() == g4.getBucketResults() == g5.getBucketResults():
    print 'PROBLEM!'

else: print 'bucketing success :)'

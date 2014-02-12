
######################################################################################
#                                                                                    #
# In this implementation, nodes are not objects, all info is centralised             #
#                                                                                    #
# Must have a directed graph for notion of parenthood in taxon tree (so be careful   #
# with ordering of args in addEdge(parentNode, childNode)                            #
#                                                                                    #
# Bucketing threshold can be specified as arg, default is 1000                       #
#                                                                                    #
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
# NOTE   : If you try adding an edge that adds a 2nd parent to a node, it will fail; #
#          this is to ensure the graph remains a tree                                #
#                                                                                    #
# NOTE   : Every node belongs to a bucket. each bucket is a node. a node can         #
#          therefore be the bucket of multiple nodes.                                #
#                                                                                    #
######################################################################################

import sys

class Tree:
    def __init__(self,name=""):
        self.name = name     # name of graph
        self.parent = {}     # dict of neighbours: keys are nodes, values are lists of nodes
        self.children = {}   # same with children
        self.nodes = {}      # dict of nodes: keys are nodes, values are bool
        self.images = {}     # dict of number of images: keys are nodes, values are number of images in synset corresponding to that node
        self.bucket = {}     # dict of buckets
        self.status = {}

    def addNode(self,nodeName,numImages=0):
        self.nodes[nodeName] = True
        self.images[nodeName] = numImages
        self.children[nodeName] = []
        

    def propagateImages(self, nodeName, numImages, parent):

        # print "propagate called with %s, %i, %s" % (nodeName, numImages, parent)
        
        if parent == []: return
        
        for parent in parent:
            try:
                self.images[parent] += numImages
            except:
                self.images[parent] = numImages

            # print "len(%s.parent[%s]) == %i" % (self, parent, len(self.parent[parent]))

            if len(self.parent[parent]) > 0:
                self.propagateImages(parent, numImages, self.parent[parent]) #self.propagateImages? self as arg?
    
        
    def addEdge(self,parentNode,childNode):
        if childNode in self.children[parentNode]:
            print 'edge already exists'
            return

        if childNode in self.parent.keys():
            print 'Error: %s already has %s as a parent' % (childNode, self.parent[childNode])
            print '       if you add %s, the graph will no longer be a tree and bucketing will malfunction' % (parentNode)
        
        self.children[parentNode].append(childNode)
        self.parent[childNode] = parentNode

        # propagate child's images to new parent only, not to all!
        # print '(addEdge): about to propagate', childNode, '\'s', self.images[childNode], 'images to all its ancestors'
        self.propagateImages(childNode, self.images[childNode], [parentNode])

            
    def getChildren(self, nodeName=''):
        # try: 
        if nodeName == '': return self.children
        else: return self.children[nodeName]
        # except: return []


    def getParent(self, nodeName=''):
        # try: 
        if nodeName == '': return self.parent
        else: return self.parent[nodeName]
        # except: return []


    def getImages(self, nodeName=''):
        # try: 
        if nodeName == '': return self.images
        else: return self.images[nodeName]
        # except: return []


    def getNodes(self):
        return self.nodes.keys()
    
    def deleteEdge(self,parentNode,childNode):
        # try :
        self.children[parentNode].remove(childNode)
        del self.parent[childNode]
        # except :
        #     return "error"

    def deleteNode(self,node):
        del self.nodes[node]
        # try :
        for otherNode in self.children[node] :
            self.children[otherNode].remove(node)
        del self.children[node]
        
        for otherNode in self.parent[node] :
            self.parent[otherNode].remove(node)
        del self.parent[node]
        
        
    def bucketAlgo(self, threshold=1000):
        # step 1: set buckets
        for node in self.nodes.keys():
            bucketNode = node
            while self.images[bucketNode] < threshold:
                # below is computationally inefficient, but python doesn't allow me to use a value as a key,
                # so I can't do bucketNode = self.parent[bucketNode]
                for parent in self.children.keys():
                    if bucketNode in self.children[parent]:
                        bucketNode = parent
                        continue
                print 'Error: %s has no bucketable ancestor'
                print '       either tree is incorrect, or you have less than 1000 images in total'
                return
            self.bucket[node] = bucketNode

        # step 2: set node statuses
        # ie figure out which nodes are classifiable, unclassifiable, unnecessary
        for node in self.nodes:
            if self.images[node] < threshold:
                self.status[node] = 'unclassifiable'
            else: self.status[node] = 'unnecessary'
            
        for node in self.nodes.keys():
            if self.status[node]=='unnecessary' and self.children[node] == []:
                self.status[node] = 'classifiable'
                continue

            for child in self.children[node]:
                if self.status[child] == 'unclassifiable':
                    self.status[node] = 'classifiable'
                    break


    def printTreeStatus(self):
        print '#total\d: %i \d(check %i)' % (len(self.nodes.keys()), len(self.status.keys()))
        result = {}
        for stat in ['classifiable', 'unnecessary', 'unclassifiable']:
            result[stat] = [node for node in self.status.keys() if self.status[node]==stat]
            # print = '#%s\d: %i' % (stat, len([node for node in self.status.keys() if self.status[node]==stat]))
        print ''


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

g1 = Tree()
g2 = Tree()
g3 = Tree()
g4 = Tree()
g5 = Tree()


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

## CASE 1: add all leaves first, then parent

# add edge involving a leaf
g1.addEdge('european tree', 'evergreen european tree')
g1.addEdge('european tree', 'palm european tree')
g1.addEdge('american tree', 'big american tree')
g1.addEdge('american tree', 'small american tree')
g1.addEdge('asian tree', 'pointy asian tree')
g1.addEdge('asian tree', 'square asian tree')
g1.addEdge('african tree', 'sexy african tree')
g1.addEdge('african tree', 'minger african tree')

# add edge involving parent only
g1.addEdge('tree', 'european tree')
g1.addEdge('tree', 'american tree')
g1.addEdge('tree', 'asian tree')
g1.addEdge('tree', 'african tree')



# CASE 2: add all parent first, then leaves

# add edge involving parent only
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
g1.bucketAlgo()
g1.printTreeStatus()
print ''

g2.bucketAlgo()
g3.bucketAlgo()
g4.bucketAlgo()
g5.bucketAlgo()

if not g1.status == g2.status == g3.status == g4.status == g5.status:
    print 'PROBLEM!'

else: print 'bucketing success :)'

import mongoHelperFunctions
from collections import Counter


if __name__ == '__main__':
    images, labels = mongoHelperFunctions.bucketing(1000,'Leaf',0.5)
    c = Counter(labels)
    total = 0
    classes = 0
    for key in c:
        total += c[key]
        classes += 1
    print c
    print 'Total images for each of the %i classes:%i'%(classes,total)
    print 'Number of label classes: %i'%(len(set(labels)))
    print 'Number of images: %i'%(len(images))
    print 'Number of labels: %i'%(len(labels))

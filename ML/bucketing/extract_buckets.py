import mongoHelperFunctions
from collections import Counter


if __name__ == '__main__':
    images, labels = mongoHelperFunctions.bucketing(1000)
    print Counter(labels)
    print len(set(labels))

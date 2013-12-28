//
//  Set.h
//  beLeaf
//
//  Created by Ashley Cutmore on 27/12/2013.
//  Copyright (c) 2013 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sample;

@interface Set : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *photos;
@end

@interface Set (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(Sample *)value;
- (void)removePhotosObject:(Sample *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end

//
//  BLEFGroup.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BLEFSpecimen;

@interface BLEFGroup : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic) int16_t order;
@property (nonatomic, retain) NSSet *specimens;
@end

@interface BLEFGroup (CoreDataGeneratedAccessors)

- (void)addSpecimensObject:(BLEFSpecimen *)value;
- (void)removeSpecimensObject:(BLEFSpecimen *)value;
- (void)addSpecimens:(NSSet *)values;
- (void)removeSpecimens:(NSSet *)values;

@end

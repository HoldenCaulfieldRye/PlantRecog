//
//  BLEFSpecimen.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BLEFGroup, BLEFImage;

@interface BLEFSpecimen : NSManagedObject

@property (nonatomic) NSTimeInterval created;
@property (nonatomic) float latitude;
@property (nonatomic) float longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) BOOL finished;
@property (nonatomic) int16_t order;
@property (nonatomic) int16_t id;
@property (nonatomic, retain) BLEFGroup *group;
@property (nonatomic, retain) NSSet *images;
@end

@interface BLEFSpecimen (CoreDataGeneratedAccessors)

- (void)addImagesObject:(BLEFImage *)value;
- (void)removeImagesObject:(BLEFImage *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end

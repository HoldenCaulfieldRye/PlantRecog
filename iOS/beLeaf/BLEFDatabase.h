//
//  BLEFDatabase.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEFGroup.h"
#import "BLEFSpecimen.h"
#import "BLEFImage.h"

@interface BLEFDatabase : NSObject

+ (NSArray*)getGroups;
+ (NSArray*)getSpecimensFromGroup:(BLEFGroup *)group;
+ (NSArray*)getImagesFromSpecimen:(BLEFSpecimen *)specimen;

+ (BLEFSpecimen*)addNewSpecimentToGroup:(BLEFGroup *)group;

+ (void)saveChanges;

+ (void) ensureGroupsExist;
+ (void) createStartingPoint;

@end

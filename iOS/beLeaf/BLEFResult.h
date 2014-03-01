//
//  BLEFResult.h
//  beLeaf
//
//  Created by Ashley Cutmore on 01/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BLEFSpecimen;

@interface BLEFResult : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * shortdesc;
@property (nonatomic) int16_t confidence;
@property (nonatomic, retain) BLEFSpecimen *specimen;

@end

//
//  Sample.h
//  beLeaf
//
//  Created by Ashley Cutmore on 27/12/2013.
//  Copyright (c) 2013 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Set;

@interface Sample : NSManagedObject

@property (nonatomic) float latitude;
@property (nonatomic) float longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) int16_t status;
@property (nonatomic) NSTimeInterval date;
@property (nonatomic, retain) id thumbnail;
@property (nonatomic, retain) NSString * imagePath;
@property (nonatomic, retain) Set *set;

@end

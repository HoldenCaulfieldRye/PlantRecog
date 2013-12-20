//
//  Sample.h
//  beLeaf
//
//  Created by Ashley Cutmore on 20/12/2013.
//  Copyright (c) 2013 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Image, Set;

@interface Sample : NSManagedObject

@property (nonatomic) NSTimeInterval taken;
@property (nonatomic) int16_t status;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id thumbnail;
@property (nonatomic) float longitude;
@property (nonatomic) float latitude;
@property (nonatomic, retain) Set *set;
@property (nonatomic, retain) Image *image;

@end

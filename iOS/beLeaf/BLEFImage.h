//
//  BLEFImage.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BLEFSpecimen;

@interface BLEFImage : NSManagedObject

@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) id thumbnail;
@property (nonatomic) NSTimeInterval date;
@property (nonatomic) BOOL uploaded;
@property (nonatomic) int16_t job;
@property (nonatomic, retain) BLEFSpecimen *specimen;

- (UIImage *)getImage;
- (void)generateThumbnailFromImage:(UIImage *)image;
- (BOOL)saveImage:(UIImage *)image;

@end

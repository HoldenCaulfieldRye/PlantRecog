//
//  BLEFObservation.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BLEFSpecimen;

@interface BLEFObservation : NSManagedObject

@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * segment;
@property (nonatomic, retain) id thumbnail;
@property (nonatomic) BOOL uploaded;
@property (nonatomic, retain) BLEFSpecimen *specimen;

- (UIImage *)getImage;
- (NSData *)getImageData;
- (UIImage *)getThumbnail;
- (void)generateThumbnailFromImage:(UIImage *)image;
- (void)saveImage:(NSData *)imageData completion:(void (^) (BOOL success))handler;

@end

//
//  BLEFObservation.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFObservation.h"
#import "BLEFSpecimen.h"
#import "BLEFDatabase.h"
#import "BLEFAppDelegate.h"
#import "BLEFServerInterface.h"


@implementation BLEFObservation

@dynamic date;
@dynamic filename;
@dynamic job;
@dynamic latitude;
@dynamic longitude;
@dynamic result;
@dynamic segment;
@dynamic thumbnail;
@dynamic uploaded;
@dynamic uploadProgress;
@dynamic specimen;

- (UIImage *)getImage
{
    NSString *imageDirectory = [BLEFObservation getImageDirectory];
    NSString* pathToFile = [imageDirectory stringByAppendingPathComponent:self.filename];
    UIImage* image = [UIImage imageWithContentsOfFile:pathToFile];
    return image;
}

- (NSData *)getImageData
{
    NSString *imageDirectory = [BLEFObservation getImageDirectory];
    NSString* pathToFile = [imageDirectory stringByAppendingPathComponent:self.filename];
    NSData* data = [NSData dataWithContentsOfFile:pathToFile];
    return data;
}

- (UIImage *)getThumbnail
{
    UIImage *thumbnail = self.thumbnail;
    return thumbnail;
}


- (void)generateThumbnailFromImage:(UIImage *)image
{
    CGRect rect = CGRectMake(0.0, 0.0, 100.0, 100.0);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    self.thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void)saveImage:(UIImage *)image completion:(void (^) (BOOL success))handler
{
    if (image != nil) {
        NSManagedObjectID* observationID = [self objectID];
        NSDate* now = [NSDate date];
        NSTimeInterval unix_timestamp = [now timeIntervalSince1970];
        NSString *name = [NSString stringWithFormat:@"%f.jpg",unix_timestamp];
        NSData* data = UIImageJPEGRepresentation(image, 1.0);
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue addOperationWithBlock:^{
            bool result = [BLEFObservation saveFile:data withFilename:name];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (result){
                    [BLEFObservation forObservation:observationID setFileNameTo:name];
                }
                handler(result);
            }];
        }];
    }
}


#pragma mark - Private Methods

- (void)willSave
{
    if ([self isDeleted]){
        [self deleteFile:self.filename];
    }
}

+ (NSString *)getImageDirectory
{
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                               NSUserDomainMask, YES);
    NSString *documentsDirectory = [directories objectAtIndex:0];
    return documentsDirectory;
}

- (BOOL)deleteFile:(NSString *)filename
{
    NSString *imageDirectory = [BLEFObservation getImageDirectory];
    NSString* pathToFile = [imageDirectory stringByAppendingPathComponent:filename];
    
    NSError *error = nil;
    return [[NSFileManager defaultManager] removeItemAtPath: pathToFile error: &error];
}

+ (BOOL)saveFile:(NSData *)data withFilename:(NSString *)filename
{
    NSString *imageDirectory = [self getImageDirectory];
    NSString* pathToFile = [imageDirectory stringByAppendingPathComponent:filename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToFile])
        return false;
    if ([[NSFileManager defaultManager] createFileAtPath:pathToFile contents:data attributes:nil]){
        return true;
    }
    return false;
}

+ (void)forObservation:(NSManagedObjectID *)observationID setFileNameTo:(NSString *)filename
{
    NSManagedObject* object = [BLEFDatabase fetchObjectWithID:observationID];
    if (object == nil){
        NSLog(@"Error fetching observation with id: %@", observationID);
        return;
    } else {
        BLEFObservation* observation = (BLEFObservation *)object;
        [observation setFilename:filename];
    }
}

@end

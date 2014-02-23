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

- (void)saveImage:(UIImage *)image
{
    if (image != nil) {
        NSManagedObjectID* observationID = [self objectID];
        dispatch_queue_t imageFileProcessing = dispatch_queue_create("imageFileProcessing",NULL);
        dispatch_async(imageFileProcessing, ^{
            NSDate* now = [NSDate date];
            NSTimeInterval unix_timestamp = [now timeIntervalSince1970];
            NSString *name = [NSString stringWithFormat:@"%f.jpg",unix_timestamp];
            NSData* data = UIImageJPEGRepresentation(image, 1.0);
            bool result = [BLEFObservation saveFile:data withFilename:name];
            NSLog(@"File Saved result: %d", result);
            if (result){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [BLEFObservation forObservation:observationID setFileNameTo:name];
                    // Send to server
                    BLEFAppDelegate* app = [[UIApplication sharedApplication] delegate];
                    BLEFServerInterface *serverInterface = [app serverinterface];
                    [serverInterface addObservationToUploadQueue:observationID];
                });
            }
        });
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
        [BLEFDatabase saveChanges];
    }
}

@end

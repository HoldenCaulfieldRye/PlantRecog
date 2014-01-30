//
//  BLEFImage.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFImage.h"
#import "BLEFSpecimen.h"


@implementation BLEFImage

@dynamic filename;
@dynamic thumbnail;
@dynamic date;
@dynamic uploaded;
@dynamic job;
@dynamic specimen;

- (void)willSave
{
    if ([self isDeleted]){
        [self deleteFile:self.filename];
    }
}

- (NSString *)getImageDirectory
{
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                               NSUserDomainMask, YES);
    NSString *documentsDirectory = [directories objectAtIndex:0];
    return documentsDirectory;
}

- (BOOL)deleteFile:(NSString *)filename
{
    NSString *imageDirectory = [self getImageDirectory];
    NSString* pathToFile = [imageDirectory stringByAppendingPathComponent:filename];
    
    NSError *error = nil;
    return [[NSFileManager defaultManager] removeItemAtPath: pathToFile error: &error];
}

- (BOOL)saveFile:(NSData *)data withFilename:(NSString *)filename
{
    NSString *imageDirectory = [self getImageDirectory];
    NSString* pathToFile = [imageDirectory stringByAppendingPathComponent:filename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToFile])
        return false;
    if ([[NSFileManager defaultManager] createFileAtPath:pathToFile contents:data attributes:nil]){
        self.filename = filename;
        return true;
    }
    return false;
}

- (BOOL)saveImage:(UIImage *)image
{
    if (image != nil) {
        NSDate* now = [NSDate date];
        NSTimeInterval unix_timestamp = [now timeIntervalSince1970];
        NSString *name = [NSString stringWithFormat:@"%f.jpg",unix_timestamp];
        
        NSData* data = UIImageJPEGRepresentation(image, 1.0);
        return [self saveFile:data withFilename:name];
    }
    return false;
}

- (UIImage *)getImage
{
    NSString *imageDirectory = [self getImageDirectory];
    NSString* pathToFile = [imageDirectory stringByAppendingPathComponent:self.filename];
    UIImage* image = [UIImage imageWithContentsOfFile:pathToFile];
    return image;
}

- (NSData *)getImageData
{
    NSString *imageDirectory = [self getImageDirectory];
    NSString* pathToFile = [imageDirectory stringByAppendingPathComponent:self.filename];
    NSData* data = [NSData dataWithContentsOfFile:pathToFile];
    return data;
}


- (void)generateThumbnailFromImage:(UIImage *)image
{
    CGSize size = image.size;
    CGFloat ratio = 0;
    if (size.width > size.height) {
        ratio = 44.0 / size.width;
    } else {
        ratio = 44.0 /size.height;
    }
    CGRect rect = CGRectMake(0.0, 0.0, ratio * size.width, ratio *size.height);
    
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    self.thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

@end

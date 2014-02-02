//
//  BLEFServerInterface.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFServerInterface.h"
#import "BLEFDatabase.h"
#import "BLEFAppDelegate.h"
#import "BLEFObservation.h"

@implementation BLEFServerInterface

- (id)init
{
    self = [super init];
    if (self) {
        self.updates = 0;
    }
    return self;
}

NSString * const BLEFUploadDidSendDataNotification = @"BLEFUploadDidSendDataNotification";

- (void)uploadObservation:(NSManagedObjectID *)observationID
{
    NSLog(@"Observation Upload called");
    NSManagedObject* fetchedObject = [self fetchObjectWithID:observationID];
    if (fetchedObject != nil){
        BLEFObservation* observation = (BLEFObservation *)fetchedObject;
        NSData *imageData = [observation getImageData];
        //NSString *urlString = @"http://sheltered-ridge-6203.herokuapp.com/upload";
        NSString *urlString = @"http://192.168.1.78:5000/upload";
        NSDictionary *params = @{@"ID": @"1234", @"auth" : @"password"};
        [self uploadFields:params andFileData:imageData toUrl:urlString];
    } else {
        NSLog(@"Error fetching observation for upload");
    }
}

#pragma mark Private Methods

- (void)uploadFields:(NSDictionary *)parameters andFileData:(NSData *)fileData toUrl:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    NSMutableData *body = [NSMutableData data];
    
    if (parameters){
        [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding]];
        }];
    }
    
    if (fileData){
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"datafile\"; filename=\"test.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:fileData]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [request setHTTPBody:body];
    NSURLConnection *serverConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [serverConnection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"didReceiveData:%@", dataAsString);
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    CGFloat dataSent = totalBytesWritten;
    CGFloat dataTotal = totalBytesExpectedToWrite;
    NSNumber *progress = [NSNumber numberWithFloat:dataSent/dataTotal];
    NSDictionary *uploadInfo = @{
                                 @"percentage" : progress
                                };
    if (self.updates % 20 == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BLEFUploadDidSendDataNotification object:nil userInfo:uploadInfo];
    }
    self.updates = self.updates + 1;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection Failed");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"didFinishLoading");
}

#pragma mark - Core Data Methods

- (NSManagedObjectContext *)getContext
{
    if (_managedObjectContext != nil) {
            return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [(BLEFAppDelegate *)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObject *)fetchObjectWithID:(NSManagedObjectID *)objectID
{
    NSManagedObjectContext *context = [self getContext];
    NSError* error = nil;
    NSManagedObject* object = [context existingObjectWithID:objectID error:&error];
    return object;
}

//TODO: Subscribe to changes in other context

@end

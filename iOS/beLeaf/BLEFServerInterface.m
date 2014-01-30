//
//  BLEFServerInterface.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFServerInterface.h"
#import "BLEFDatabase.h"

@implementation BLEFServerInterface

- (void) uploadImage:(BLEFImage *)image;
{
    NSData *imageData = [image getImageData];
    NSString *urlString = @"http://sheltered-ridge-6203.herokuapp.com/upload";
    NSDictionary *params = @{@"ID": @"1234", @"auth" : @"password"};
    [self uploadFields:params andFileData:imageData toUrl:urlString];
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
    NSLog(@"didSendData-%ld / %ld",(long)totalBytesWritten,(long)totalBytesExpectedToWrite);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection Failed");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"didFinishLoading");
}

@end

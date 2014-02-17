//
//  BLEFUIObservationCell.m
//  beLeaf
//
//  Created by Ashley Cutmore on 11/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFUIObservationCell.h"

@interface BLEFUIObservationCell ()


@end

@implementation BLEFUIObservationCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)updateProgress:(NSNotification *)notification
{
    NSDictionary* uploadInfo = notification.userInfo;
    NSManagedObjectID *uploadID = [uploadInfo objectForKey:@"objectID"];
    if ([uploadID isEqual:_objIB]){
        NSNumber* progress = [uploadInfo objectForKey:@"percentage"];
        float progressF = [progress floatValue];
        [_progressBar setProgress:progressF animated:true];
    }
}

-(void)updateJobStatus:(NSNotification *)notification
{
    NSDictionary* uploadInfo = notification.userInfo;
    NSManagedObjectID *uploadID = [uploadInfo objectForKey:@"objectID"];
    NSNumber *status = [uploadInfo objectForKey:@"status"];
    BOOL statusB = [status boolValue];
    if ([uploadID isEqual:_objIB]){
        [self updateJobStatusUI:statusB];
        [_progressBar tintColorDidChange];
        [_progressBar setNeedsDisplay];
        [_progressBar setProgress:0.9f animated:true];
        [_progressBar setProgress:1.0f];
    }
}

-(void)updateJobStatusUI:(BOOL)status
{
    if (status)
        [_progressBar setTintColor:[UIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:1.0f]];
    else
        [_progressBar setTintColor:[UIColor colorWithRed:0.0f green:139/255.0f blue:251/255.0f alpha:1.0f]];
}

@end

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

@end

//
//  BLEFServerConnection.m
//  beLeaf
//
//  Created by Ashley Cutmore on 04/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFServerConnection.h"

@implementation BLEFServerConnection

- (id)init
{
    self = [super init];
    if (self) {
        self.progress = 0;
        self.jobUpdate = false;
        self.upload = false;
    }
    return self;
}

@end

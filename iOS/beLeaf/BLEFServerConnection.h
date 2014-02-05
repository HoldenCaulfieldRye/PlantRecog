//
//  BLEFServerConnection.h
//  beLeaf
//
//  Created by Ashley Cutmore on 04/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEFServerConnection : NSURLConnection

@property (strong, nonatomic) NSManagedObjectID *objID;
@property (nonatomic) CGFloat progress;

@end

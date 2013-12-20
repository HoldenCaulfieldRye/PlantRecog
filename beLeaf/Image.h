//
//  Image.h
//  beLeaf
//
//  Created by Ashley Cutmore on 20/12/2013.
//  Copyright (c) 2013 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sample;

@interface Image : NSManagedObject

@property (nonatomic, retain) id image;
@property (nonatomic, retain) Sample *sample;

@end

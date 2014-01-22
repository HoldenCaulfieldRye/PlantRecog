//
//  BLEFSampleDataViewController.h
//  beLeaf
//
//  Created by Ashley Cutmore on 01/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ManagedObjects.h"

@interface BLEFSampleDataViewController : UIViewController

@property (nonatomic, weak) Sample *sample;
@property (weak, nonatomic) IBOutlet UIImageView *sampleImage;

@end

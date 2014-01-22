//
//  BLEFSampleDataViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 01/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFSampleDataViewController.h"

@interface BLEFSampleDataViewController ()

@end

@implementation BLEFSampleDataViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (self.sample != nil) {
        self.sampleImage.image = [self loadImageFromPath:self.sample.imagePath];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage*)loadImageFromPath:(NSString *)path
{
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                               NSUserDomainMask, YES);
    NSString *documentsDirectory = [directories objectAtIndex:0];
    NSString* fullPath = [documentsDirectory stringByAppendingPathComponent:path];
    UIImage* image = [UIImage imageWithContentsOfFile:fullPath];
    return image;
}

@end

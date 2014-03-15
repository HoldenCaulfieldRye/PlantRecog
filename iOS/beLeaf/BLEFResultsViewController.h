//
//  BLEFResultsViewController.h
//  beLeaf
//
//  Created by Ashley Cutmore on 08/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEFDatabase.h"
#import "BLEFSpecimen.h"

@interface BLEFResultsViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) BLEFSpecimen *specimen;
@property (strong, nonatomic) BLEFDatabase * database;

@end

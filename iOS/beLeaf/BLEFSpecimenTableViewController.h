//
//  BLEFSpecimenTableViewController.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEFGroup.h"

@interface BLEFSpecimenTableViewController : UITableViewController

@property (strong, nonatomic) BLEFGroup* group;
@property (strong, nonatomic) NSArray *Specimen;

- (IBAction)addButtonPressed:(id)sender;

@end

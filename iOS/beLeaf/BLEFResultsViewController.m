//
//  BLEFResultsViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 08/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFResultsViewController.h"
#import "BLEFDatabase.h"

@interface BLEFResultsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@end

@implementation BLEFResultsViewController

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
	// Do any additional setup after loading the view.
    NSManagedObject *fetchedObj = [BLEFDatabase fetchObjectWithID:[self resultID]];
    if (fetchedObj){
        BLEFObservation *observation = (BLEFObservation*)fetchedObj;
        NSString *result = [observation result];
        if (result)
            [[self resultLabel] setText:result];
        else
            [[self resultLabel] setText:@"No classification..yet"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

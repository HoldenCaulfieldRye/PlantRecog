//
//  BLEFResultsViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 08/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFResultsViewController.h"
#import "BLEFDatabase.h"
#import "BLEFresultLabel.h"

@interface BLEFResultsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;

@end

@implementation BLEFResultsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom Init
    }
    return self;
}

- (id)init
{
    self = [super init];
    NSLog(@"INIT");
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if (_specimen){

        
        NSInteger resultY = 0;
        NSInteger resultWidth = self.resultsArea.bounds.size.width;
        NSInteger resultHeight = 30;
        NSSet *results = [_specimen results];
        if (results != nil){
            for (BLEFResult *result in results) {
                BLEFresultLabel *resultLabel = [[BLEFresultLabel alloc] initWithFrame:CGRectMake(0, resultY, resultWidth, resultHeight)
                                                                           confidence:[result confidence]];
                [resultLabel setText:[result name]];
                resultY = resultY + resultHeight;
                [_resultsArea addSubview:resultLabel];
            }
        }        
        
        // Images
        
        
        NSArray *observations = [_database getObservationsFromSpecimen:_specimen];
        NSMutableArray *images = [[NSMutableArray alloc] init];
        
        for (BLEFObservation *observation in observations) {
            UIImage *image = [observation getImage];
            [images addObject:image];
        }
        
        NSArray *imageArray = [NSArray arrayWithArray:images];
        
        for (int i = 0; i < [imageArray count]; i++) {
            // Create an imageView object in every 'page' of our scrollView.
            CGRect frame;
            frame.origin.x = self.imageScrollView.frame.size.width * i;
            frame.origin.y = 0;
            frame.size = self.imageScrollView.frame.size;
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            imageView.image = [imageArray objectAtIndex:i];
            [self.imageScrollView addSubview:imageView];
        }
        //Set the content size of our scrollview according to the total width of our imageView objects.
        self.imageScrollView.contentSize = CGSizeMake(self.imageScrollView.frame.size.width * [imageArray count], self.imageScrollView.frame.size.height);
        if ([imageArray count] > 1){
            self.pageControl.numberOfPages = [imageArray count];
        } else {
            self.pageControl.hidden = true;
        }
    }
    //self.mainScrollView.frame = self.view.frame;
    //self.mainScrollView.autoresizesSubviews = NO;
    //self.mainScrollView.contentSize = CGSizeMake(self.view.frame.size.width, 2000);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Image ScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.imageScrollView.frame.size.width;
    int page = floor((self.imageScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

@end

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
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;

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

    if (_specimen){

        
        /*
        // JSON PARSE
         NSString *result = nil;
        if (result){
            NSDictionary* resultDic = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
            __block NSString *formatedResult = @"";
            if (resultDic){
                [resultDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
                    formatedResult = [formatedResult stringByAppendingString:[NSString stringWithFormat:@"%@ : %@ \n\n", key, value]];
                }];
            }
            [[self resultLabel] setText:formatedResult];
        } else {
            [[self resultLabel] setText:@"No classification..yet"];
        }
        */
        [[self resultLabel] setText:@"No classification..yet"];
        
        
        // Images
        
        // TODO : Get images for specimen
        
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
        self.pageControl.numberOfPages = [imageArray count];
    }
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

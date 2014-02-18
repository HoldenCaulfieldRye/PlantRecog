//
//  BLEFSpeicmenObservationsViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 30/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFSpeicmenObservationsViewController.h"
#import "BLEFDatabase.h"
#import "BLEFAppDelegate.h"
#import "BLEFUIObservationCell.h"
#import "BLEFResultsViewController.h"

@implementation BLEFSpeicmenOberservationsViewController

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
	[self loadCollectionData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self loadCollectionData];
    [self.collectionView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    for (int i = 0; i < ([[self collectionView] numberOfItemsInSection:0] - 1); i++){
        BLEFUIObservationCell *cell = (BLEFUIObservationCell *)[[self collectionView] cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        [center removeObserver:cell];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Collection View Methods

- (void)loadCollectionData
{
    self.observations = [BLEFDatabase getObservationsFromSpecimen:self.specimen];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.observations count] + 1;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.observations count]){
        // Get Observation
        BLEFObservation *observation = [self.observations objectAtIndex:indexPath.row];
        NSManagedObjectID *objID = [observation objectID];
    
        // Get Cell
        static NSString *identifier = @"Cell";
        BLEFUIObservationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        [cell setObjIB:objID];
    
        // Set Thumbnail
        [[cell imageView] setImage:[observation getThumbnail]];
    
        // Set Progress Bar
        if ([observation uploaded]){
            [[cell progressBar] setProgress:1.0];
        } else if ([observation uploadProgress]){
            [[cell progressBar] setProgress:[observation uploadProgress]];
        } else {
            [[cell progressBar] setProgress:0];
        }
        
        if ([observation result])
            [cell updateJobStatusUI:true];
        else
            [cell updateJobStatusUI:false];
    
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
        [center addObserver:cell selector:@selector(updateProgress:) name:BLEFUploadDidSendDataNotification object:nil];
        [center addObserver:cell selector:@selector(updateJobStatus:) name:BLEFJobDidSendDataNotification object:nil];
    
        return cell;
    }
    NSString *identifier = @"AddCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    return cell;
}

#pragma mark - Navigation Methods

- (IBAction)updateButtonClicked:(id)sender
{
    NSLog(@"Update button clicked");
     NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:BLEFNetworkRetryNotification object:nil];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.observations count]){
        BLEFUIObservationCell *cell = (BLEFUIObservationCell *)[collectionView cellForItemAtIndexPath:indexPath];
        if ([[cell progressBar] progress] == 1.0){
            [self performSegueWithIdentifier:@"observationToResult" sender:[cell objIB]];
        }
    } else {
        [self showCamerView];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ObservationToCamera"]) {
        BLEFCameraViewController *destination = [segue destinationViewController];
        [destination setDelegate:sender];
    } else if ([[segue identifier] isEqualToString:@"observationToResult"]){
        BLEFResultsViewController *destination = [segue destinationViewController];
        [destination setResultID:sender];
    }
}

#pragma mark - New Photo Methods

- (void)showCamerView
{
    [self performSegueWithIdentifier:@"ObservationToCamera" sender:self];
}

-(void)blefCameraViewControllerDidDismiss:(BLEFCameraViewController *)cameraViewController
{
   [cameraViewController dismissViewControllerAnimated:YES completion:^{NSLog(@"blef image picker canceled");}];
}

-(void)blefCameraViewController:(BLEFCameraViewController *)cameraViewController tookPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
    NSLog(@"Photo Taken delegate method");
    BLEFObservation* observation = [BLEFDatabase addNewObservationToSpecimen:self.specimen];
    [observation generateThumbnailFromImage:photo];
    [observation setSegment:info[@"segment"]];
    [observation setLatitude:[info[@"lat"] doubleValue]];
    [observation setLongitude:[info[@"long"] doubleValue]];
    [BLEFDatabase saveChanges];
    [observation saveImage:photo];
}


@end

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
#import "BLEFServerInterface.h"

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
    return [self.observations count];
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Get Observation
    BLEFObservation *observation = [self.observations objectAtIndex:indexPath.row];
    NSManagedObjectID *objID = [observation objectID];
    
    // Get Cell
    static NSString *identifier = @"Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    // Set Thumbnail
    UIImageView *cellImageView = (UIImageView *)[cell viewWithTag:100];
    cellImageView.image = [observation getThumbnail];
    
    // Set Progress Bar
    UIProgressView* progressbar = (UIProgressView *)[cell viewWithTag:50];
    [progressbar setProgress:0];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:BLEFUploadDidSendDataNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *notification)
     {
         NSDictionary* uploadInfo = notification.userInfo;
         NSManagedObjectID *uploadID = [uploadInfo objectForKey:@"objectID"];
         
         if ([uploadID isEqual:objID]){
         NSNumber* progress = [uploadInfo objectForKey:@"percentage"];
         float progressF = [progress floatValue];
         dispatch_async(dispatch_get_main_queue(), ^{
             NSLog(@"Progress:%f", progressF);
             [progressbar setProgress:progressF animated:true];
         });
         }
     }];
    
    return cell;
}

#pragma mark - Navigation Methods

- (IBAction)addPhotoButtonClicked:(id)sender
{
    NSLog(@"Camera clicked");
    //[self displayImagePicker];
    [self showCamerView];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    UIProgressView *progressbar = (UIProgressView *)[cell viewWithTag:50];
    if ([progressbar progress] == 1.0){
        
        [self performSegueWithIdentifier:@"observationToResult" sender:NULL];
        
    } else if ([progressbar progress] == 0) {
        BLEFObservation *observation = [self.observations objectAtIndex:indexPath.row];
    
        BLEFAppDelegate* app = [[UIApplication sharedApplication] delegate];
        BLEFServerInterface *serverInterface = [app serverinterface];
    
        [serverInterface uploadObservation:[observation objectID]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ObservationToCamera"]) {
        BLEFCameraViewController *destination = [segue destinationViewController];
        [destination setDelegate:sender];
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
    [BLEFDatabase saveChanges];
    [observation saveImage:photo];
}


@end

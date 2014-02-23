//
//  BLEFCameraViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 04/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFCameraViewController.h"

@interface BLEFCameraViewController ()

@property (nonatomic) BOOL displayPicker;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *componentSelection;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@end

@implementation BLEFCameraViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // custom init
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.delegate = self;
    _location = nil;
    [_locationManager startUpdatingLocation];
    
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.allowsEditing = NO;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.showsCameraControls = NO;
        self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        NSArray *cameraViews =  [[NSBundle mainBundle] loadNibNamed:@"BLEFCameraView" owner:self options:nil];
        UIView *camerView = [cameraViews objectAtIndex:0];
        self.imagePickerController.cameraOverlayView = camerView;
    } else {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    self.displayPicker = true;
}

-(void)viewDidAppear:(BOOL)animated
{
    if (self.displayPicker)
        [self presentViewController:self.imagePickerController animated:NO completion:^{
            [self.activityIndicator stopAnimating];
        }];
    self.displayPicker = false;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom Camera View Methods
- (IBAction)userCancel:(id)sender
{
    [self.imagePickerController dismissViewControllerAnimated:NO completion:^{
            [delegate blefCameraViewControllerDidDismiss:self];
    }];
}

- (IBAction)takePhoto:(id)sender
{
    [self flash];
    [self.imagePickerController takePicture];
}

-(void)flash
{
    self.imagePickerController.cameraOverlayView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
    [UIView animateWithDuration:0.5f animations:^{
        self.imagePickerController.cameraOverlayView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    }];
}


- (IBAction)userSwipeRight:(id)sender {
    NSInteger numberofSegments = [self.componentSelection numberOfSegments];
    NSInteger selectedSegment =  [self.componentSelection selectedSegmentIndex];
    if (selectedSegment < numberofSegments)
        [self.componentSelection setSelectedSegmentIndex:selectedSegment+1];
}

- (IBAction)userSwipeLeft:(id)sender {
    NSInteger selectedSegment =  [self.componentSelection selectedSegmentIndex];
    if (selectedSegment > 0)
        [self.componentSelection setSelectedSegmentIndex:(selectedSegment -1)];
}

#pragma mark - Image Picker Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage* image = info[UIImagePickerControllerOriginalImage];
    
    __block NSNumber *longitude = [NSNumber numberWithDouble:0.0];
    __block NSNumber *latitude = [NSNumber numberWithDouble:0.0];
    if (_location != nil){
        longitude = [NSNumber numberWithDouble:_location.coordinate.longitude];
        latitude = [NSNumber numberWithDouble:_location.coordinate.latitude];
    }
    
    NSString *segment;
    NSInteger selectedSegment =  [self.componentSelection selectedSegmentIndex];
    switch (selectedSegment) {
        case 0:
            segment = @"entire";
            break;
        case 1:
            segment = @"branch";
            break;
        case 2:
            segment = @"stem";
            break;
        case 3:
            segment = @"fruit";
            break;
        case 4:
            segment = @"flower";
            break;
        case 5:
            segment = @"leaf";
            break;
        default:
            break;
    }
    
    NSDictionary *observationInfo = @{@"segment": segment, @"lat": latitude, @"long": longitude};
    
    [delegate blefCameraViewController:self tookPhoto:image withInfo:observationInfo];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:NO completion:NULL];
    [delegate blefCameraViewControllerDidDismiss:self];
}

#pragma mark - Location Services
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    _location = [locations lastObject];
}

@end

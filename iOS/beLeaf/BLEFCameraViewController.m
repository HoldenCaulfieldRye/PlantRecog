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
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.allowsEditing = NO;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.showsCameraControls = NO;
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
    NSLog(@"User Cancel");
    [self.imagePickerController dismissViewControllerAnimated:NO completion:^{
            [delegate blefCameraViewControllerDidDismiss:self];
    }];
}

- (IBAction)takePhoto:(id)sender
{
    NSLog(@"User Take Photo");
    [self.imagePickerController takePicture];
}


- (IBAction)userSwipeRight:(id)sender {
    NSLog(@"User swiped ->");
    NSInteger numberofSegments = [self.componentSelection numberOfSegments];
    NSInteger selectedSegment =  [self.componentSelection selectedSegmentIndex];
    if (selectedSegment < numberofSegments)
        [self.componentSelection setSelectedSegmentIndex:selectedSegment+1];
}

- (IBAction)userSwipeLeft:(id)sender {
    NSLog(@"User swiped <-");
    NSInteger selectedSegment =  [self.componentSelection selectedSegmentIndex];
    if (selectedSegment > 0)
        [self.componentSelection setSelectedSegmentIndex:(selectedSegment -1)];
}

#pragma mark - Image Picker Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"imagePicker took photo");
    UIImage* image = info[UIImagePickerControllerOriginalImage];
    [delegate blefCameraViewController:self tookPhoto:image withInfo:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"Did cancel");
    [picker dismissViewControllerAnimated:NO completion:NULL];
    [delegate blefCameraViewControllerDidDismiss:self];
}

@end

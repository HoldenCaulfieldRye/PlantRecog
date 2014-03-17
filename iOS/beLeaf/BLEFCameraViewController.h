//
//  BLEFCameraViewController.h
//  beLeaf
//
//  Created by Ashley Cutmore on 02/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BLEFDatabase.h"

@interface BLEFCameraViewController : UIViewController
    <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) BLEFDatabase * database;

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (strong, nonatomic) UIView *whiteView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentSelection;

// Buttons
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *CameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *FinishButton;

// AV
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureStillImageOutput *AVImageOutput;

- (IBAction)takePhotoButtonPressed:(id)sender;
- (IBAction)finishedSessionButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;

@end

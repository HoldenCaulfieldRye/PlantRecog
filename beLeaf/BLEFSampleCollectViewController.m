//
//  BLEFSampleCollectViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 20/12/2013.
//  Copyright (c) 2013 DocMcs13group12. All rights reserved.
//

#import "BLEFSampleCollectViewController.h"

@interface BLEFSampleCollectViewController ()

@property (strong, nonatomic) AVCaptureSession *captureSession;

@end

@implementation BLEFSampleCollectViewController

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
    self.captureSession = [[AVCaptureSession alloc] init];
    [self startCaptureSession];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Navigation

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self stopCaptureSession];
}

#pragma mark Capure Session Methods

- (void) startCaptureSession
{
    // Input
    AVCaptureSession *captureSession = self.captureSession;
    [captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    
    if ([captureSession canAddInput:deviceInput]){
        [captureSession addInput:deviceInput];
    
        // Output
        AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
        [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        
        // Input > Output
        [captureSession addOutput:dataOutput];
        
        // Display
        AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        CALayer *rootLayer = [[self view] layer];
        [rootLayer setMasksToBounds:YES];
        [previewLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height)];
        [rootLayer insertSublayer:previewLayer atIndex:0];
        
        // Start
        [captureSession startRunning];
        NSLog(@"Capture Session Started");
    }
}

- (void) stopCaptureSession
{
    if ([self.captureSession isRunning]) {
        [self.captureSession stopRunning];
        NSLog(@"Capture Session Stopped");
    }
}

- (void) addVideoFrameToSet
{
    // Grab output buffer
    // Process
    // Grab context
    // Add new sample
    // save context
    // inform uploader of new content
}

@end

//
//  BLEFCameraViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 02/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFCameraViewController.h"

@interface BLEFCameraViewController ()

@property (strong, nonatomic) UIImageView * imageReviewView;
@property (strong, nonatomic) NSMutableArray * sessionImages;

@end

@implementation BLEFCameraViewController

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
    
    // Database
    // Setup UI Database
    if (_database == nil){
    _database = [[BLEFDatabase alloc] init];
    }
    
    // Camera Images
    _sessionImages = [NSMutableArray arrayWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
    
    // UI
    _imageReviewView = [[UIImageView alloc] init];
    _imageReviewView.frame = _previewView.bounds;
    [_previewView addSubview:_imageReviewView];
    [_segmentSelection addTarget:self action:@selector(segmentSelectionChanged:) forControlEvents:UIControlEventValueChanged];
    
    // AV
    [self setupCaptureSession];
    [self startCaptureSession];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopCaptureSession];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Methods

- (IBAction)takePhotoButtonPressed:(id)sender
{
    if ([_captureSession isRunning]){
        [self captureImageWithHandler:^(NSData *imageData) {
            [self processImageData:imageData];
        }];
    } else {
        [self hideImage];
        [self deleteImageData:[_segmentSelection selectedSegmentIndex]];
        [self startCaptureSession];
    }
}

- (IBAction)finishedSessionButtonPressed:(id)sender
{
    // Create Specimen
    BLEFSpecimen *newSpecimen = [_database newSpecimen];
    
    // For each segment with data - create observation
    
    for (id dataObject in _sessionImages) {
        if ([dataObject isKindOfClass:[NSData class]]){
            
            BLEFObservation *newObservation = [_database addNewObservationToSpecimen:newSpecimen];

            [newObservation generateThumbnailFromImage:[UIImage imageWithData:(NSData *)dataObject]];
            
            [newObservation saveImage:(NSData *)dataObject completion:^(BOOL success) {
                [_database saveChanges];
            }];
        }
    }

    // Dismiss view

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)processImageData:(NSData *)imageData
{
    UIImage *image = [UIImage imageWithData:imageData];
    [self displayImage:image];
    [_sessionImages insertObject:imageData atIndex:[_segmentSelection selectedSegmentIndex]];
    // TODO...?
}

- (void)deleteImageData:(NSInteger)segmentNumber
{
    [_sessionImages replaceObjectAtIndex:segmentNumber withObject:[NSNull null]];
}

- (void)displayImage:(UIImage *)image
{
    [_captureSession stopRunning];
    _imageReviewView.image = image;
    _imageReviewView.hidden = NO;
    [_previewView bringSubviewToFront:_imageReviewView];
}

- (void)hideImage
{
    if (_imageReviewView){
        _imageReviewView.hidden = YES;
        _imageReviewView.image = nil;
        _imageReviewView.opaque = NO;
    }
}

- (void)segmentSelectionChanged:(id)sender
{
    id objectAtIndex = [_sessionImages objectAtIndex:[_segmentSelection selectedSegmentIndex]];
    
    if ([objectAtIndex isKindOfClass:[NSData class]]){
        UIImage *imageForSegment = [UIImage imageWithData:(NSData *)objectAtIndex];
        [self displayImage:imageForSegment];
    } else {
        [self hideImage];
        [self startCaptureSession];
    }
}

#pragma mark - AV Methods

- (void) setupCaptureSession {
    //Setup Capture Session
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    
    //Setup Input Device
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error: &error];
    
    //Add Input Device to Capture Session
    if ( [_captureSession canAddInput:deviceInput] ){
        [_captureSession addInput:deviceInput];
    }
    
    //Setup Output
    _AVImageOutput = [[AVCaptureStillImageOutput alloc] init];
    if ([_captureSession canAddOutput:_AVImageOutput]){
        [_captureSession addOutput:_AVImageOutput];
    }
    
    //Setup Preview
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [_previewView layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:rootLayer.bounds];
    [rootLayer insertSublayer:previewLayer atIndex:0];
}

- (void) startCaptureSession {
    [_captureSession startRunning];
}

- (void) stopCaptureSession {
    [_captureSession stopRunning];
}

- (void) captureImageWithHandler:(void (^) (NSData *imageData))handler
{
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _AVImageOutput.connections) {
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    if (videoConnection == nil){
        handler(nil);
        return;
    }
    
    [_AVImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
        {
            NSData *_imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            handler(_imageData);
        }
    ];
}




@end

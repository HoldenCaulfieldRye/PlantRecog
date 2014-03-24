//
//  BLEFCameraViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 02/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFCameraViewController.h"
#import "BLEFCaptureBuffer.h"

@interface BLEFCameraViewController ()

@property (strong, nonatomic) UIImageView * imageReviewView;
@property (strong, nonatomic) BLEFCaptureBuffer *captureBuffer;
@property (strong, nonatomic) NSArray *segments;
@property (nonatomic) NSInteger selectionIndexBuffer;

@end

@implementation UIImage (crop)

- (UIImage *)squareCrop
{
    CGFloat destSize = 512.0f;
    CGRect rect = CGRectMake(0, 0, destSize, destSize);
    
    UIGraphicsBeginImageContext(rect.size);
    
    if(self.size.width != self.size.height)
    {
        CGFloat ratio;
        CGRect destRect;
        
        if (self.size.width > self.size.height)
        {
            ratio = destSize / self.size.height;
            
            CGFloat destWidth = self.size.width * ratio;
            CGFloat destX = (destWidth - destSize) / 2.0;
            
            destRect = CGRectMake(-destX, 0, destWidth, destSize);
            
        }
        else
        {
            ratio = destSize / self.size.width;
            
            CGFloat destHeight = self.size.height * ratio;
            CGFloat destY = (destHeight - destSize) / 2.0;
            
            destRect = CGRectMake(0, -destY, destSize, destHeight);
        }
        [self drawInRect:destRect];
    }
    else
    {
        [self drawInRect:rect];
    }
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

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
    
    // Setup Buffer
    _segments = @[@"entire", @"leaf" , @"flower", @"fruit"];
    _captureBuffer = [[BLEFCaptureBuffer alloc] initWithSlots:_segments usingDatabase:_database];
    
    // Setup Camera
    [self setupCaptureSession];
    
    // UI
    _imageReviewView = [[UIImageView alloc] initWithFrame:_previewView.bounds];
    [_imageReviewView setContentMode:UIViewContentModeScaleAspectFill];
    [_previewView addSubview:_imageReviewView];
    
    _whiteView = [[UIView alloc] initWithFrame:[_previewView bounds]];
    [_whiteView setHidden:TRUE];
    [_whiteView setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:1.0f]];
    [_previewView addSubview:_whiteView];
    
    [_segmentSelection addTarget:self action:@selector(segmentSelectionChanged:) forControlEvents:UIControlEventValueChanged];
    _selectionIndexBuffer = 0;
    
    [self UI_cameraMode];
    
    // Start Camera
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

void runOnMainQueueWithoutDeadlocking(void (^codeblock)(void))
{
    if ([NSThread isMainThread])
    {
        codeblock();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), codeblock);
    }
}

- (void)UI_cameraMode
{
    runOnMainQueueWithoutDeadlocking(^{

        [[self activityIndicator] stopAnimating];
        [[self segmentSelection] setEnabled:true];
        [[self cancelButton] setEnabled:true];
        [[self CameraButton] setEnabled:true];
        [[self retakeButton] setEnabled:false];
        [[self retakeButton] setTitle:@""];
        if ([_segmentSelection selectedSegmentIndex] < ([_segmentSelection numberOfSegments] -1)){
            [[self FinishButton] setEnabled:true];
            [[self FinishButton] setTitle:@"Skip"];
        } else if ([[self captureBuffer] completeCount] > 0){
            [[self FinishButton] setEnabled:true];
            [[self FinishButton] setTitle:@"GO"];
        } else {
            [[self FinishButton] setEnabled:false];
            [[self FinishButton] setTitle:@"GO"];
        }
    });
}

- (void)UI_reTakeMode
{
    runOnMainQueueWithoutDeadlocking(^{
        [[self activityIndicator] stopAnimating];
        [[self segmentSelection] setEnabled:true];
        [[self cancelButton] setEnabled:true];
        [[self CameraButton] setEnabled:false];
        [[self retakeButton] setEnabled:true];
        [[self retakeButton] setTitle:@"Retake"];
        if ([_segmentSelection selectedSegmentIndex] < ([_segmentSelection numberOfSegments] -1)){
            [[self FinishButton] setEnabled:true];
            [[self FinishButton] setTitle:@"Next"];
        } else if ([[self captureBuffer] completeCount] > 0){
            [[self FinishButton] setEnabled:true];
            [[self FinishButton] setTitle:@"GO"];
        } else {
            [[self FinishButton] setEnabled:false];
            [[self FinishButton] setTitle:@"GO"];
        }
    });
}

- (void)UI_reviewMode
{
    runOnMainQueueWithoutDeadlocking(^{
        [[self activityIndicator] stopAnimating];
        [[self segmentSelection] setEnabled:true];
        [[self cancelButton] setEnabled:true];
        [[self CameraButton] setEnabled:false];
        [[self retakeButton] setEnabled:false];
        [[self retakeButton] setTitle:@""];
        if ([_segmentSelection selectedSegmentIndex] < ([_segmentSelection numberOfSegments] -1)){
            [[self FinishButton] setEnabled:true];
            [[self FinishButton] setTitle:@"Next"];
        } else if ([[self captureBuffer] completeCount] > 0){
            [[self FinishButton] setEnabled:true];
            [[self FinishButton] setTitle:@"GO"];
        } else {
            [[self FinishButton] setEnabled:false];
            [[self FinishButton] setTitle:@"GO"];
        }
    });
}

- (void)UI_busyMode
{
    runOnMainQueueWithoutDeadlocking(^{
        [[self activityIndicator] startAnimating];
        [[self cancelButton] setEnabled:false];
        [[self CameraButton] setEnabled:false];
        [[self retakeButton] setEnabled:false];
        [[self retakeButton] setTitle:@""];
        [[self FinishButton] setEnabled:false];
        [[self segmentSelection] setEnabled:false];
    });
}

- (NSString *)currentSegmentSelection
{
    return [_segments objectAtIndex:[_segmentSelection selectedSegmentIndex]];
}

- (IBAction)takePhotoButtonPressed:(id)sender
{
    if ([_captureSession isRunning]){
        [self UI_busyMode];
        [self flashWhile:^{
            [self captureImageWithHandler:^(NSData *imageData) {
                [self processImageData:imageData];
                [self UI_reTakeMode];
            }];
        }];
    }
}

- (IBAction)finishedSessionButtonPressed:(id)sender
{
    bool finish = ([_segmentSelection selectedSegmentIndex] == ([_segmentSelection numberOfSegments] - 1));
    
    if (finish){
        [_captureBuffer completeSlotNamed:[self currentSegmentSelection] completion:^(BOOL success) {
            [_captureBuffer completeCapture];
            [[_captureBuffer database] saveChanges];
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    } else {
        [_segmentSelection setSelectedSegmentIndex:([_segmentSelection selectedSegmentIndex] + 1)];
        [self segmentSelectionChanged:nil];
    }
}

- (IBAction)cancelButtonPressed:(id)sender {
    [_captureBuffer deleteSession];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)retakeButtonPressed:(id)sender {
    if (![_captureSession isRunning]){
        [self UI_cameraMode];
        [self hideImage];
        [_captureBuffer removeDataForSlot:[self currentSegmentSelection]];
        [self startCaptureSession];
    }
}

- (void)processImageData:(NSData *)imageData
{
    UIImage *largerImage = [UIImage imageWithData:imageData];
    
    UIImage *croppedImage = [largerImage squareCrop];
    
    [self displayImage:croppedImage];
    [_captureBuffer addData:UIImageJPEGRepresentation(croppedImage, 1.0f) toSlot:[self currentSegmentSelection]];
}

- (void)displayImage:(UIImage *)image
{
    [_captureSession stopRunning];
    _imageReviewView.image = image;
    _imageReviewView.hidden = NO;
    [_previewView bringSubviewToFront:_imageReviewView];
}

- (void)flashWhile:(void (^) (void))handler
{
    [_previewView bringSubviewToFront:_whiteView];
    [_whiteView setHidden:false];
    _whiteView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
    
    if (handler) handler();
    
    [UIView animateWithDuration:0.75f animations:^{
        _whiteView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    } completion:^(BOOL finished) {
        [_whiteView setHidden:true];
    }];
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
    [_captureBuffer completeSlotNamed:[_segments objectAtIndex:_selectionIndexBuffer] completion:^(BOOL success){
        if (success){
            [[_captureBuffer database] saveChanges];
        }
    }];
    
    _selectionIndexBuffer = [[self segmentSelection] selectedSegmentIndex];
    
    
    UIImage *image = [_captureBuffer imageForSlotNamed:[self currentSegmentSelection]];
    if (image != nil){
        [self displayImage:image];
        [self UI_reviewMode];
    } else {
        [self UI_cameraMode];
        [self hideImage];
        [self startCaptureSession];
    }
}

#pragma mark - AV Methods

- (void) setupCaptureSession {
    //Setup Capture Session
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession setSessionPreset:AVCaptureSessionPresetiFrame960x540];
    
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
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [_previewView layer];
    [rootLayer setMasksToBounds:YES];
    [_previewLayer setFrame:rootLayer.bounds];
    [rootLayer insertSublayer:_previewLayer atIndex:0];
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

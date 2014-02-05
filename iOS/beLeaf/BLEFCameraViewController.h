//
//  BLEFCameraViewController.h
//  beLeaf
//
//  Created by Ashley Cutmore on 04/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BLEFCameraViewController;


@protocol BLEFCameraViewControllerDelegate

-(void)blefCameraViewControllerDidDismiss:(BLEFCameraViewController *)cameraViewController;
-(void)blefCameraViewController:(BLEFCameraViewController *)cameraViewController tookPhoto:(UIImage *)photo withInfo:(NSDictionary *)info;

@end

@interface BLEFCameraViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, assign) id  delegate;

@end

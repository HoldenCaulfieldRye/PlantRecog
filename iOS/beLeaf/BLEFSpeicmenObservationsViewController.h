//
//  BLEFSpeicmenObservationsViewController.h
//  beLeaf
//
//  Created by Ashley Cutmore on 30/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEFSpecimen.h"
#import "BLEFCameraViewController.h"

@interface BLEFSpeicmenOberservationsViewController : UICollectionViewController <BLEFCameraViewControllerDelegate>

@property (strong, nonatomic) BLEFSpecimen* specimen;
@property (strong, nonatomic) NSArray *observations;
extern NSString * const BLEFUploadDidSendDataNotification;

@end

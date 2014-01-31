//
//  BLEFSetTableViewController.h
//  beLeaf
//
//  Created by Ashley Cutmore on 19/12/2013.
//  Copyright (c) 2013 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLEFSetTableViewController : UITableViewController <UIActionSheetDelegate,
                    UINavigationControllerDelegate, UIImagePickerControllerDelegate,
                    NSURLConnectionDataDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (strong, nonatomic) NSArray *samples;

- (IBAction)displayImageSourceMenu;

@end

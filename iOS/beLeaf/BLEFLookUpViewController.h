//
//  BLEFLookUpViewController.h
//  beLeaf
//
//  Created by Ashley Cutmore on 23/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLEFLookUpViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSString *lookup;
- (IBAction)doneButtonPressed:(id)sender;

@end

//
//  BLEFLookUpViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 23/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFLookUpViewController.h"

@interface BLEFLookUpViewController ()

@end

@implementation BLEFLookUpViewController

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
    [_webView setDelegate:self];
    NSURL *url;
    if ([self lookup] == nil){
        url = [NSURL URLWithString:@"http://www.google.co.uk"];
    } else {
        NSString *urlAsString = [NSString stringWithFormat:@"https://www.google.com/search?tbm=isch&q=%@ (plant/tree)", _lookup];
        urlAsString = [urlAsString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        url = [NSURL URLWithString:urlAsString];
    }
    [self openUrl:url];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)openUrl:(NSURL*)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [[self webView] loadRequest:request];
}

- (IBAction)doneButtonPressed:(id)sender {
    [[self webView] stopLoading];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [_activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_activityIndicator stopAnimating];
}

@end

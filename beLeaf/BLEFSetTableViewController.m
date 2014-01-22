//
//  BLEFSetTableViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 19/12/2013.
//  Copyright (c) 2013 DocMcs13group12. All rights reserved.
//

#import "BLEFSetTableViewController.h"
#import "ManagedObjects.h"
#import "BLEFAppDelegate.h"
#import "BLEFSampleDataViewController.h"

@interface BLEFSetTableViewController ()

@property Sample *uploading;
@property NSMutableDictionary *sampleUploads;
@property UIImage *pickedImage;

@end

@implementation BLEFSetTableViewController

@synthesize samples;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.uploading = nil;
    self.pickedImage = nil;
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to force upload"];
    [refresh addTarget:self action:@selector(forceUpload:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
    
    
    self.tableView.rowHeight = 50;
    [self loadTableData];
    [self.tableView reloadData];
    [self uploadNextSample];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Navigation


 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
     if ([[segue identifier] isEqualToString:@"tableViewtoSampleData"]) {
         BLEFSampleDataViewController *sampleView  = [segue destinationViewController];
         sampleView.sample = sender;
     }
 }

- (void)viewWillDisappear:(BOOL)animated
{
    // Return cells to their normal state
    [self.tableView setEditing:NO];
}

- (IBAction)unwindToTableView:(UIStoryboardSegue *)segue
{
    //Return here from another scene
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [samples count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    //Configure the cell...
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Sample *sample = [self.samples objectAtIndex:indexPath.row];
    
    // Thumbnail
    [cell.imageView setImage:sample.thumbnail];
    [cell.imageView setHidden:false];
    
    // Activity Indicator
    UIActivityIndicatorView *activityIndicator;
    activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:1];
    cell.textLabel.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.0 alpha:0.0];

    /* 
    // 0 : Error
    // 1 : Processing
    // 2 : In upload queue
    // 3 : Uploading
    // 4 : Awaiting response
    // 5 : Completed
    */
    
    switch (sample.status) {
        case 0:
            [activityIndicator stopAnimating];
            cell.textLabel.text = @"Error";
            break;
        case 1:
            [activityIndicator startAnimating];
            cell.textLabel.text = @"Processing";
            break;
        case 2:
            cell.textLabel.text = @"In upload queue";
            [activityIndicator stopAnimating];
            break;
        case 3:
            cell.textLabel.text = @"Uploading";
            [activityIndicator startAnimating];
            break;
        case 4:
            cell.textLabel.text = @"Waiting responce";
            [activityIndicator stopAnimating];
            break;
        case 5:
            [activityIndicator stopAnimating];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.text = sample.name;
            break;
        default:
            break;
    }
    return cell;
}

- (void)loadTableData
{
    BLEFAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    // Grab context
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    // Construct request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sample" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // Sort alphabetically
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDesriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDesriptors];
    
    // Fetch
    NSError *error = nil;
    self.samples = [context executeFetchRequest:fetchRequest error:&error];
}

- (void)addPhoto:(UIImage *)photo
{
    
    BLEFAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    // Grab context
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    // Grab default set
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityType = [NSEntityDescription entityForName:@"Set"
                                                            inManagedObjectContext:context];
    [fetchRequest setEntity:entityType];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name==%@", @"Default Set"];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    Set *defaultSet = [fetchedObjects objectAtIndex:0];
    
    // Create new Sample
    Sample *sample = [NSEntityDescription insertNewObjectForEntityForName:@"Sample" inManagedObjectContext:context];
    sample.name = @"Name of plant";
    
    [defaultSet addPhotosObject:sample];
    [sample setSet:defaultSet];
    
    [appDelegate saveContext];
    [self loadTableData];
    [self.tableView reloadData];
    
    // Process Sample on a background thread
    dispatch_queue_t sampleProcessing = dispatch_queue_create("Sample Processing",NULL);
    
    dispatch_async(sampleProcessing, ^{
        
        // save image to FS
        NSString *photoPath = [self saveImage:photo];
        sample.imagePath = photoPath;
        
        // create thumbnail
        CGSize size = photo.size;
        CGFloat ratio = 0;
        if (size.width > size.height) {
            ratio = 44.0 / size.width;
        } else {
            ratio = 44.0 /size.height;
        }
        CGRect rect = CGRectMake(0.0, 0.0, ratio * size.width, ratio *size.height);
        
        UIGraphicsBeginImageContext(rect.size);
        [photo drawInRect:rect];
        sample.thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            sample.status = 2;
            [appDelegate saveContext];
            [self loadTableData];
            [self.tableView reloadData];
            [self uploadNextSample];
        });
        
    });
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // If row is being deleted
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Remove row's predicate from database
        Sample *sample = [self.samples objectAtIndex:indexPath.row];
        BLEFAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [appDelegate.managedObjectContext deleteObject:sample];
        [appDelegate saveContext];
        
        // Refresh table's source array to reflect change
        [self loadTableData];
        
        // Animate remove row from table
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Can't delete a sample mid-upload
    Sample *sample = [self.samples objectAtIndex:indexPath.row];
    return (sample.status != 1 && sample.status != 3);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Sample *sample = [self.samples objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"tableViewtoSampleData" sender:sample];
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark Server

- (void)uploadFields:(NSDictionary *)parameters andFileData:(NSData *)fileData toUrl:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    NSMutableData *body = [NSMutableData data];
    
    if (parameters){
        [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding]];
        }];
    }
    
    if (fileData){
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"datafile\"; filename=\"test.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:fileData]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [request setHTTPBody:body];
    NSURLConnection *serverConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [serverConnection start];
}

- (NSNumber*)uploadImage:(UIImage*)image
{
    NSNumber *result = @1;
    NSData *imageData = UIImageJPEGRepresentation(image, 10.0);
    NSString *urlString = @"http://sheltered-ridge-6203.herokuapp.com/upload";
    NSDictionary *params = @{@"ID": @"1234", @"auth" : @"password"};
    [self uploadFields:params andFileData:imageData toUrl:urlString];
    return result;
}

- (void)uploadNextSample
{
    if (! self.uploading){
        Sample *sample = nil;
        for (Sample *sampleAtIndex in samples) {
            if (sampleAtIndex.status == 2){
                sample = sampleAtIndex;
                break;
            }
        }
        if (sample){
            self.uploading = sample;
            UIImage *image = [self loadImageFromPath:sample.imagePath];
            [self uploadImage:image];
        }
    }
}

- (void)forceUpload:(UIRefreshControl *)refresh
{
    [refresh endRefreshing];
    [self uploadNextSample];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"didReceiveData:%@", dataAsString);
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    
    if  (self.uploading.status != 3){
        NSLog(@"Connection didSendData");
        self.uploading.status = 3;
        [self.tableView reloadData];
    }
    //NSLog(@"%ld / %ld",(long)totalBytesWritten,(long)totalBytesExpectedToWrite);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection Failed");
    self.uploading = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"didFinishLoading");
    Sample *sample = self.uploading;
    self.uploading = nil;
    sample.status = 4;
    
    BLEFAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate saveContext];
    [self.tableView reloadData];
    [self uploadNextSample];
}

#pragma mark Photo Select

- (IBAction)displayImageSourceMenu
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
    UIActionSheet *imageSourceMenu = [[UIActionSheet alloc] initWithTitle:@"Image Source"
                                                            delegate:self
                                                            cancelButtonTitle:@"Neither"
                                                            destructiveButtonTitle:nil
                                                            otherButtonTitles:@"Camera", @"Library", nil];
    [imageSourceMenu showInView:self.view];
    } else {
        [self actionSheet:nil clickedButtonAtIndex:1];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    BOOL showPicker = TRUE;
    switch (buttonIndex) {
        case 0:
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        case 1:
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        default:
            showPicker = FALSE;
            break;
    }
    if (showPicker){
    [self presentViewController:imagePicker animated:YES completion:NULL];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.pickedImage = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{[self addPhoto:self.pickedImage]; self.pickedImage = nil;}];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark File System

- (UIImage*)loadImageFromPath:(NSString *)path
{
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [directories objectAtIndex:0];
    NSString* fullPath = [documentsDirectory stringByAppendingPathComponent:path];
    UIImage* image = [UIImage imageWithContentsOfFile:fullPath];
    return image;
}

- (NSString *)saveImage: (UIImage*)image
{
    if (image != nil)
    {
        NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        NSString *documentsDirectory = [directories objectAtIndex:0];
        
        // Set photo name using current date and time
        NSDate* now = [NSDate date];
        NSTimeInterval unix_timestamp = [now timeIntervalSince1970];
        NSString *name = [NSString stringWithFormat:@"%f.jpg",unix_timestamp];
        
        NSString* path = [documentsDirectory stringByAppendingPathComponent:name];
        // get date
        NSData* data = UIImageJPEGRepresentation(image, 1.0);
        [data writeToFile:path atomically:YES];
        return name;
    } else return nil;
}

@end

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

@interface BLEFSetTableViewController ()

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
    
    [self loadTableData];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    cell.textLabel.text = sample.name;
    [cell.imageView setImage:sample.thumbnail];

    return cell;
}

#pragma mark - Private Methods

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
    [self.tableView reloadData];
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
    sample.name = @"Photo";
    
    [defaultSet addPhotosObject:sample];
    [sample setSet:defaultSet];
    
    // Create new Image
    Image *image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];
    image.image = photo;
    sample.image = image;
    
    // Create thumbnail
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
    
    [appDelegate saveContext];
    [self loadTableData];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Remove row's predicate from database
        Sample *sample = [self.samples objectAtIndex:indexPath.row];
        BLEFAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [appDelegate.managedObjectContext deleteObject:sample];
        [appDelegate saveContext];
        [self loadTableData];
        
        // Animage remove row from table
        //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        /* Error */
        
    }
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

#pragma mark Photo Select

- (IBAction)displayImageSourceMenu
{
    UIActionSheet *imageSourceMenu = [[UIActionSheet alloc] initWithTitle:@"Image Source"
                                                            delegate:self
                                                            cancelButtonTitle:@"Neither"
                                                            destructiveButtonTitle:nil
                                                            otherButtonTitles:@"Camera", @"Library", nil];
    [imageSourceMenu showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    
    
    switch (buttonIndex) {
        case 0:
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        case 1:
        default:
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
    }
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    [self addPhoto:chosenImage];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Navigation
/*
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

- (IBAction)unwindToTableView:(UIStoryboardSegue *)segue
{
    
}
@end

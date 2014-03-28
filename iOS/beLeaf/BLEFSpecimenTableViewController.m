//
//  BLEFSpecimenTableViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFAppDelegate.h"
#import "BLEFSpecimenTableViewController.h"
#import "BLEFResultsViewController.h"
#import "BLEFCameraViewController.h"
#import "BLEFSpecimen.h"
#import "BLEFDatabase.h"
#import "BLEFSpecimenTableViewCell.h"

@interface BLEFSpecimenTableViewController ()

@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) BLEFDatabase *database;

@end

@implementation BLEFSpecimenTableViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        //custom init
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup UI Database
    _database = [[BLEFDatabase alloc] init];
    BLEFAppDelegate *appdelegate = (BLEFAppDelegate *)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext *UIContext = [appdelegate generateManagedObjectContext];
    [_database setManagedObjectContext:UIContext];
    
    // Load TableView
    self.tableView.rowHeight = 50;
    [self loadTableData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    _fetchedResultsController = nil;
}

#pragma mark - Table View Methods

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil){
        return _fetchedResultsController;
    }
    
    NSFetchedResultsController *fetchController = [_database fetchSpecimen];
    fetchController.delegate = self;
    _fetchedResultsController = fetchController;
    return fetchController;
}

- (void)loadTableData
{
    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error]){
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id sectionInfo = [[[self fetchedResultsController] sections] objectAtIndex:section];
    NSInteger number = [sectionInfo numberOfObjects];
    return number;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    BLEFSpecimen *specimen = (BLEFSpecimen *)[_fetchedResultsController objectAtIndexPath:indexPath];
    BLEFSpecimenTableViewCell *customCell = (BLEFSpecimenTableViewCell*)cell;
    [customCell styleCellWithSpecimen:specimen];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //Configure the cell...
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        BLEFSpecimen *specimen = (BLEFSpecimen *)[_fetchedResultsController objectAtIndexPath:indexPath];
        [specimen setForDeletion:true];
        [self loadTableData];
        [_database saveChanges];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
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


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation

- (IBAction)addButtonPressed:(id)sender
{
    [self performSegueWithIdentifier:@"HOMEtoCAMERA" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"HOMEtoRESULT"]) {
        BLEFResultsViewController *destination = [segue destinationViewController];
        [destination setDatabase:_database];
        [destination setSpecimen:(BLEFSpecimen *)sender];
    } else if ([[segue identifier] isEqualToString:@"HOMEtoCAMERA"]){
        BLEFCameraViewController *destination = [segue destinationViewController];
        [destination setDatabase:_database];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Return cells to their normal state
    //[self.tableView setEditing:NO];
}

- (IBAction)unwindToTableView:(UIStoryboardSegue *)segue
{
    //Return here from another scene
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BLEFSpecimen *specimen = [_fetchedResultsController objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"HOMEtoRESULT" sender:specimen];
}

#pragma mark - Fetched Controller Delegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end

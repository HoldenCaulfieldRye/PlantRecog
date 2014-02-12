//
//  BLEFSpecimenTableViewController.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFSpecimenTableViewController.h"
#import "BLEFSpeicmenObservationsViewController.h"
#import "BLEFSpecimen.h"
#import "BLEFDatabase.h"

@interface BLEFSpecimenTableViewController ()

@end

@implementation BLEFSpecimenTableViewController

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
    
    if (self.group == nil){
        [BLEFDatabase ensureGroupsExist];
        self.group = [[BLEFDatabase getGroups] objectAtIndex:0];
    }

    self.tableView.rowHeight = 50;
    [self loadTableData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Methods

- (void)loadTableData
{
    self.Specimen = [BLEFDatabase getSpecimensFromGroup:self.group];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self Specimen] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //Configure the cell...
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // BLEFSpecimen *specimen = [[self Specimen] objectAtIndex:indexPath.row];
    
    // Thumbnail
    //[cell.imageView setImage:thumbnail];
    //[cell.imageView setHidden:false];
    
    cell.textLabel.text = @"Unnamed Specimen";
    
    return cell;
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


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation

- (IBAction)addButtonPressed:(id)sender
{
    // create new speimen
    [BLEFDatabase addNewSpecimentToGroup:self.group];
    [BLEFDatabase saveChanges];
    [self loadTableData];
    [self.tableView reloadData];
    // go to specimen ?
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"specimenToObservations"]) {
        BLEFSpeicmenOberservationsViewController *destination = [segue destinationViewController];
        [destination setSpecimen:sender];
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
    BLEFSpecimen* specimen = [self.Specimen objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"specimenToObservations" sender:specimen];
}

@end

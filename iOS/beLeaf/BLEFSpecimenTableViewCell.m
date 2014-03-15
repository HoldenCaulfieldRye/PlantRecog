//
//  BLEFSpecimenTableViewCell.m
//  beLeaf
//
//  Created by Ashley Cutmore on 06/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFSpecimenTableViewCell.h"
#import "BLEFSpecimen.h"
#import "BLEFResult.h"
#import "BLEFObservation.h"

@class BLEFSpecimen;

@implementation BLEFSpecimenTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)styleCellWithSpecimen:(BLEFSpecimen *)specimen
{
    if (specimen != nil){
        if ([specimen.results count] == 0){
            [self.textLabel setText:@"Proccessing..."];
        } else {
            BLEFResult *result = [specimen.results anyObject];
            [self.textLabel setText: [result name]];
        }
        
        if ([specimen.observations count] > 0){
            UIImage *thumb = [[specimen.observations anyObject] getThumbnail];
            [[self imageView] setImage:thumb];
        }
    }
}

@end

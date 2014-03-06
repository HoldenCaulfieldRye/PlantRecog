//
//  BLEFSpecimenTableViewCell.h
//  beLeaf
//
//  Created by Ashley Cutmore on 06/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BLEFSpecimen;

@interface BLEFSpecimenTableViewCell : UITableViewCell

- (void)styleCellWithSpecimen:(BLEFSpecimen *)specimen;

@end

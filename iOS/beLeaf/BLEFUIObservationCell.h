//
//  BLEFUIObservationCell.h
//  beLeaf
//
//  Created by Ashley Cutmore on 11/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLEFUIObservationCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSManagedObjectID *objIB;

-(void)updateProgress:(NSNotification *)notification;

@end

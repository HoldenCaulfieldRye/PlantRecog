//
//  BLEFresultLabel.h
//  beLeaf
//
//  Created by Ashley Cutmore on 18/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DACircularProgressView.h"

@interface BLEFresultLabel : UILabel

@property (strong, nonatomic) DACircularProgressView *beleafDisplay;
- (void)setProgress:(CGFloat)newProgress;
- (void)animate;
- (id)initWithFrame:(CGRect)frame confidence:(CGFloat)level;

@end

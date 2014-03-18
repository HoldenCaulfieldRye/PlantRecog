//
//  BLEFresultLabel.m
//  beLeaf
//
//  Created by Ashley Cutmore on 18/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFresultLabel.h"

@interface BLEFresultLabel ()

@property (nonatomic) CGFloat beleafLevel;

@end

@implementation BLEFresultLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // custom init
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    _beleafDisplay = [[DACircularProgressView alloc] initWithFrame:CGRectMake(self.frame.size.width-25, 0, 25, 25)];
    [_beleafDisplay setTrackTintColor:[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0]];
    _beleafLevel = 0;
    [self addSubview:_beleafDisplay];
    [super drawRect:rect];
}

- (void)setProgress:(CGFloat)newProgress
{
    _beleafLevel = newProgress;
    [_beleafDisplay setProgress:newProgress];
}

- (void)animate
{
    [_beleafDisplay setProgress:_beleafLevel animated:true];
}


@end

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

- (id)initWithFrame:(CGRect)frame confidence:(CGFloat)level
{
    self = [super initWithFrame:frame];
    if (self) {
        _beleafLevel = level;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    if (_beleafDisplay == nil){
        _beleafDisplay = [[DACircularProgressView alloc] initWithFrame:CGRectMake(self.frame.size.width-25, 0, 25, 25)];
        [_beleafDisplay setProgressTintColor:[UIColor colorWithRed:0.4 green:0.4353 blue:0.29412 alpha:1.0]];
        [_beleafDisplay setTrackTintColor:[UIColor colorWithWhite:0.7 alpha:0.7]];
        [_beleafDisplay setThicknessRatio:1.0f];
        [_beleafDisplay setProgress:_beleafLevel];
        [self addSubview:_beleafDisplay];
    }
    [super drawRect:rect];
}

- (void)setProgress:(CGFloat)newProgress
{
    _beleafLevel = newProgress;
    //[_beleafDisplay setProgress:newProgress];
}

- (void)animate
{
    [_beleafDisplay setProgress:_beleafLevel animated:true];
}


@end

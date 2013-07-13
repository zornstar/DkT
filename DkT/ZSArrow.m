//
//  ZSArrow.m
//  DkTp
//
//  Created by Matthew Zorn on 6/30/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "ZSArrow.h"
#import <QuartzCore/QuartzCore.h>

@interface ZSArrow ()

@property (nonatomic) double direction;
@property (nonatomic, strong) UIColor *color;

@end

@implementation ZSArrow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.borderColor = [UIColor clearColor].CGColor;
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    
    CGPoint points[3] = { CGPointMake(0, self.frame.size.height), CGPointMake(self.frame.size.width/2., 0), CGPointMake(self.frame.size.width, self.frame.size.height) };
    
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, points[0].x, points[0].y);
    CGContextAddLineToPoint(ctx, points[1].x, points[1].y);
    CGContextAddLineToPoint(ctx, points[2].x, points[2].y);
    CGContextAddLineToPoint(ctx, points[0].x, points[0].y);
    CGContextSetFillColorWithColor(ctx, self.color.CGColor);
    CGContextFillPath(ctx);
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, points[0].x, points[0].y);
    CGContextAddLineToPoint(ctx, points[1].x, points[1].y);
    CGContextAddLineToPoint(ctx, points[2].x, points[2].y);
    
    CGContextSetLineWidth(ctx, self.layer.borderWidth);
    CGContextSetStrokeColorWithColor(ctx, self.layer.borderColor);
    CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
    CGContextStrokePath(ctx);
    
    self.layer.borderWidth = 0.0;
    
    self.transform = CGAffineTransformMakeRotation(self.direction);
    
    
}

+(ZSArrow *) arrowWithFrame:(CGRect)frame direction:(double)direction color:(UIColor *)color
{
    ZSArrow *arrow = [[ZSArrow alloc] initWithFrame:frame];
    arrow.direction = direction;
    arrow.color = color;
    return arrow;
}
@end

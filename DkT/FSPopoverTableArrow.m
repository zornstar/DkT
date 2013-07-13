//
//  FSPopoverTableView.m
//  DkTp
//
//  Created by Matthew Zorn on 6/2/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "FSPopoverTableArrow.h"
#import <QuartzCore/QuartzCore.h>

@implementation FSPopoverTableArrow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.direction = FSPopoverTableArrowDirectionUp;
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
    CGContextSetFillColorWithColor(ctx, self.arrowColor.CGColor);
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
    self.transform = CGAffineTransformMakeRotation(self.direction * M_PI_2);
    
    
}


@end

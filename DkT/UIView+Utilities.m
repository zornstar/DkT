//
//  UIView+Utilities.m
//  DkTp
//
//  Created by Matthew Zorn on 7/6/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "UIView+Utilities.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (Utilities)

-(void) roundCorners:(UIRectCorner)corners
{
    UIBezierPath* rounded = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(5.0, 5.0)];
    
    CAShapeLayer* shape = [[CAShapeLayer alloc] init];
    [shape setPath:rounded.CGPath];
    
    self.layer.mask = shape;
}

@end

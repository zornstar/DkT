//
//  UIView+Utilities.m
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


- (UIViewController *)viewController {
    if ([self.nextResponder isKindOfClass:UIViewController.class])
        return (UIViewController *)self.nextResponder;
    else
        return nil;
}

-(void) clipToBoundsRecursive:(UIView *)someView
{
    NSLog(@"%@", someView);
    someView.clipsToBounds = NO;
    for (UIView *v in someView.subviews)
    {
        [self clipToBoundsRecursive:v];
    }
}

@end

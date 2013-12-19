//
//  UIView+Utilities.h
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Utilities)

-(void) roundCorners:(UIRectCorner)corners;
- (UIViewController *)viewController;

/* Debug */
-(void) clipToBoundsRecursive:(UIView *)someView;

@end

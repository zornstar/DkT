//
//  UIImage+Utilities.h
//  DkTp
//
//  Created by Matthew Zorn on 5/26/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Utilities)

- (UIImage *)imageWithColor:(UIColor *)color;
+(UIImageView *)imageViewWithView:(UIView *)view;
+(UIImage *) imageWithView:(UIView *)view;
+(UIImage *) imageWithString:(NSString *)str font:(UIFont *)font size:(CGSize)size color:(UIColor *)color backgroundColor:(UIColor *)color;

@end

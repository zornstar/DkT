//
//  UIImage+Utilities.h
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Utilities)

- (UIImage *)imageWithColor:(UIColor *)color;
+(UIImageView *)imageViewWithView:(UIView *)view;
+(UIImage *) imageWithString:(NSString *)str font:(UIFont *)font size:(CGSize)size color:(UIColor *)color backgroundColor:(UIColor *)color;
+(UIImage *) imageOfColor:(UIColor *)color size:(CGSize)size;
@end

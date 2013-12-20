//
//  UIColor+DkT.h
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (DkT)

+(UIColor *)activeColor;
+(UIColor *)inactiveColor;
+(UIColor *)textColor;
+(UIColor *)darkerTextColor;
+(UIColor *)lighterTextColor;
+(UIColor *)inactiveColorDark;
+(UIColor *)activeColorLight;

@end

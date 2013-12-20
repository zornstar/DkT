//
//  UIColor+DkT.m
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "UIColor+DkT.h"

@implementation UIColor (DkT)

+ (UIColor *)activeColor
{
    static UIColor* color = nil;
    if (color == nil)
    {
        color = kActiveColor;
    }
    return color;
}

+ (UIColor *)inactiveColor
{
    static UIColor* color = nil;
    if (color == nil)
    {
        color = kInactiveColor;
    }
    return color;
}

+ (UIColor *)textColor
{
    static UIColor* color = nil;
    if (color == nil)
    {
        color = kTextColor;
    }
    return color;
}

+ (UIColor *)darkerTextColor
{
    static UIColor* color = nil;
    if (color == nil)
    {
        color = kDarkTextColor;
    }
    return color;
}

+ (UIColor *)lighterTextColor
{
    static UIColor* color = nil;
    if (color == nil)
    {
        color = kLightTextColor;
    }
    return color;
}

+ (UIColor *)inactiveColorDark
{
    static UIColor* color = nil;
    if (color == nil)
    {
        color = kInactiveColorDark;
    }
    return color;
}

+ (UIColor *)activeColorLight
{
    static UIColor* color = nil;
    if (color == nil)
    {
        color = kActiveColorLight;
    }
    return color;
}


@end

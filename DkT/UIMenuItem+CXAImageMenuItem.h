//
//  UIMenuItem+CXAImageMenuItem.h
//  CXAMenuItem
//
//  Created by Chen Xian'an on 1/3/13.
//  Copyright (c) 2013 lazyapps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIMenuItem (CXAImageMenuItem)

- (id)cxa_initWithTitle:(NSString *)title action:(SEL)action image:(UIImage *)image;
- (id)cxa_initWithTitle:(NSString *)title action:(SEL)action image:(UIImage *)image hidesShadow:(BOOL)hidesShadow;
- (id)cxa_initWithTitle:(NSString *)title font:(UIFont *)font action:(SEL)action;
- (void)cxa_setImage:(UIImage *)image forTitle:(NSString *)title;
- (void)cxa_setImage:(UIImage *)image hidesShadow:(BOOL)hidesShadow forTitle:(NSString *)title;
- (void)cxa_setFont:(UIFont *)font forTitle:(NSString *)title;

@end

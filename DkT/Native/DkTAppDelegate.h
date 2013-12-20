//
//  DkTAppDelegate.h
//  DkTp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JRSwizzle.h"

@class DkTRootViewController;

@interface DkTAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) DkTRootViewController *viewController;

@end
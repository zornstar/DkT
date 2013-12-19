//
//  RECAPTabViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DkTTabBar;

@protocol DkTTabBarViewControllerDelegate <NSObject>

@optional

-(void) didFinishRotationAnimation:(UIInterfaceOrientation)fromInterfaceOrientation;

@end

@interface DkTTabViewController : UIViewController

@property (nonatomic, strong) DkTTabBar *tabBar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong, readonly) NSMutableArray *viewControllers;
@property (nonatomic, readonly) NSUInteger selectedIndex;
@property (nonatomic, weak) id<DkTTabBarViewControllerDelegate>delegate;

@end

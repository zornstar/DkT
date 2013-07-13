//
//  RECAPSettingsChildViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 6/25/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DkTSettingsCell.h"

@interface DkTSettingsChildViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic, strong) DkTSettingsCell *cell;
@property (nonatomic) DkTSettingsIconPosition position;
@property (nonatomic) CGRect frame;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *contentView;

- (id)initWithSettingsCell:(DkTSettingsCell *)cell;
-(void) addContentView;

@end

#import "DkTSettingsTableViewController.h"
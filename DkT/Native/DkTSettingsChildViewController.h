
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
@property (nonatomic, strong) UIScrollView *containerView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIControl *button;

- (id)initWithSettingsCell:(DkTSettingsCell *)cell;

@end

#import "DkTSettingsTableViewController.h"
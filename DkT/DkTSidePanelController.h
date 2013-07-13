//
//  RECAPSidePanelController.h
//  RECAPp
//
//  Created by Matthew Zorn on 6/24/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PKRevealController.h"

@class DkTLoginViewController;

@class DkTSettingsViewController;



@interface DkTSidePanelController : UIViewController

@property (nonatomic, strong) DkTLoginViewController *loginViewController;
@property (nonatomic, strong) DkTSettingsViewController *settingsViewController;
@property (nonatomic, strong) UIView *containerView;

-(void) resignWithCompletion:(PKDefaultCompletionHandler)completion;

@end

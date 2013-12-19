//
//  RECAPLoginViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PACERClient.h"
#import "DkTSession.h"

@class FSButton;

typedef NS_OPTIONS(NSUInteger, DkTPanelVisibility) {
    DkTLoginPanelVisible = 0,
    DkTRecentPanelVisible = 1,
    DkTLoggedInPanelVisible = 2
};

typedef NS_OPTIONS(NSUInteger, DkTLoginStatus) {
    DkTLoggedOut = 0,
    DkTLoggingIn = 1,
    DkTLoggedIn = 2
};

@interface DkTLoginViewController : UIViewController <UITextFieldDelegate, PACERClientProtocol, UITableViewDataSource, UITableViewDelegate, DkTSessionDelegate>

@property (nonatomic, getter = isModal) BOOL modal;
@property (nonatomic, readonly) DkTLoginStatus status;

-(void) toggleLoggedInView:(BOOL)visible;
-(void) toggleUserView:(BOOL)visible;

@end

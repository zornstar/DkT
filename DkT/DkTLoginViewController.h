//
//  RECAPLoginViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PACERClient.h"

@class FSButton;

@interface DkTLoginViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate, PACERClientProtocol, UITableViewDataSource, UITableViewDelegate>

+(void) presentAsPopover:(UIViewController *)viewController size:(CGSize)size;

@end

//
//  RECAPDocketViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PACERClient.h"
#import "DkTDocketTableViewController.h"
#import "DkTDetailViewController.h"

@class DkTDocket;

@interface DkTDocketViewController : UIViewController <PACERClientProtocol>

@property (nonatomic, strong) DkTDocketTableViewController *masterViewController;
@property (nonatomic, strong) DkTDetailViewController *detailViewController;
@property (nonatomic, strong) UISplitViewController *splitViewController;
@property (nonatomic, strong, readonly) DkTDocket *docket;

-(id) initWithDocket:(DkTDocket *)dkt;

@end

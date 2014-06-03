
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DkTDetailViewController.h"
#import "DkTDocketTableViewController.h"
#import "PACERClient.h"

@class DkTDocket;

/* shell for a DocketTableViewController and a DkTDetailViewController
 
 iPad implementation uses a UISplitViewController
 
 DkTDocketViewController
    UISplitViewController
 |------------------------------------------------|
 |                |                               |
 |                |                               |
 |                |                               |
 | UINavCtr       |   UINavCtr                    |
 |   DkTDocketTVC |       DkTDetailVC             |
 |                |                               |
 |                |                               |
 |                |                               |
 |                |                               |
 |                |                               |
 |------------------------------------------------|
 
 iPod implementation uses a PKRevealController
 
 DkTDocketViewController
    PKRevealController
 
 |----------------|
 |    |           |
 |    |           |
 |    |           |
 | 1  |    3      |
 |  2 |     4     |
 |    |           |
 |    |           |
 |    |           |
 |----------------|
 
 1 = UINavigationController
 2 = DkTDocketTVC
 3 = UINavigationController
 4 = DkTDetailVC
 
 */
@interface DkTDocketViewController : UIViewController <PACERClientProtocol>

@property (nonatomic, strong) DkTDocketTableViewController *masterViewController;
@property (nonatomic, strong) DkTDetailViewController *detailViewController;
@property (nonatomic, strong) UISplitViewController *splitViewController;
@property (nonatomic, strong, readonly) DkTDocket *docket;

-(id) initWithDocket:(DkTDocket *)dkt;

@end

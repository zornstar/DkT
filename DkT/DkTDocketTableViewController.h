//
//  RECAPDocketTableViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RECAPClient.h"
#import "DkTDocket.h"
#import "FSPopoverTableArrow.h"
#import "DkTDownloadManager.h"


@class DkTDetailViewController, DkTDocketTableView;

@interface DkTDocketTableViewController : UITableViewController <PACERClientProtocol, RECAPClientProtocol, UIAlertViewDelegate, DkTDownloadManagerProtocol>

@property (nonatomic, strong) NSArray *docketEntries;
@property (nonatomic, strong) DkTDocket *docket;

@property (nonatomic, weak) DkTDetailViewController *detailViewController;

@end

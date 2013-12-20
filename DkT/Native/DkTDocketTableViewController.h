//
//  RECAPDocketTableViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "RECAPClient.h"
#import "DkTDocket.h"
#import "DkTDownloadManager.h"
#import "PSMenuItem.h"
#import "UIMenuItem+CXAImageMenuItem.h"

@class DkTDetailViewController, DkTDocketTableView;

@interface DkTDocketTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PACERClientProtocol, UISearchDisplayDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, DkTDownloadManagerProtocol>

@property (nonatomic, strong) NSArray *docketEntries;
@property (nonatomic, weak) DkTDocket *docket;
@property (nonatomic, getter = isRoot) BOOL root;
@property (nonatomic, getter = isLocal) BOOL local;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITableView *searchTableView;
@property (nonatomic, weak) DkTDetailViewController *detailViewController;

-(void) configureTableView;

@end

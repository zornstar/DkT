//
//  RECAPBookmarkViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DkTBookmarkManager.h"
#import "DkTBookmarkCell.h"
#import "PACERClient.h"


@interface DkTBookmarkViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DkTBookmarkManagerDelegate, PACERClientProtocol>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) DkTBookmarkManager *bookmarkManager;
@property (nonatomic, strong, readonly) NSMutableArray *bookmarks;

@end

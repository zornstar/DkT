
//
//  Created by Matthew Zorn on 6/26/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DkTSettingsChildViewController.h"

@interface DkTSettingsTableViewController : DkTSettingsChildViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

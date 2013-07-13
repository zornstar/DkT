//
//  RECAPShareViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 6/28/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSettingsChildViewController.h"

@interface DkTShareViewController : DkTSettingsChildViewController <UITableViewDataSource, UITableViewDelegate>


@property (nonatomic, strong) UITableView *tableView;

@end

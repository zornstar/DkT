
//
//  Created by Matthew Zorn on 5/27/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PACERClient.h"

@class FSButton;

@interface DkTSearchResultsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PACERClientProtocol>

@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSString * nextPage;
@property (nonatomic, strong)  FSButton* backButton;

@end

//
//  RECAPMultiDocSelectionViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 6/13/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RECAPClient.h"
#import "PACERClient.h"

@interface DkTMultiDocSelectionViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PACERClientProtocol, RECAPClientProtocol>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *docketEntries;

+(void) presentAsPopover:(UIViewController *)viewController size:(CGSize)size choices:(NSArray *)choices;
@end

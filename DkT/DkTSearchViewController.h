//
//  RECAPSearchViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PACERClient.h"
#import "FSButton.h"
#import "CKCalendarView.h"

@interface DkTSearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, PACERClientProtocol, CKCalendarDelegate>

@property (nonatomic, strong) UITextField *caseNumber;
@property (nonatomic, strong) UITextField *partyName;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic, strong) NSArray *controls;
@property (nonatomic, strong) NSArray *labels;

@property (nonatomic, strong) FSButton *searchPACERButton;

@property (nonatomic, readonly, getter = isLoggedIn) BOOL loggedIn;
-(void) postSearchResults:(NSArray *)results;

@end

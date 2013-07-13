//
//  RECAPDocumentsViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DkTDocumentManager.h"

@interface DkTDocumentsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DkTDocumentManagerDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

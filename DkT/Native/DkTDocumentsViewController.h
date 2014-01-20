
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DkTDocumentManager.h"
#import <MessageUI/MessageUI.h>

@interface DkTDocumentsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DkTDocumentManagerDelegate, UIDocumentInteractionControllerDelegate, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

//
//  RECAPDetailViewController.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "DkTDocketTableViewController.h"
#import "DkTDocumentManager.h"

@class DkTDocketEntry;

@interface DkTDetailViewController : UIViewController <UISplitViewControllerDelegate, MFMailComposeViewControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, weak) DkTDocketEntry *docketEntry;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) DkTFile *file;
@property (nonatomic, weak) DkTDocketTableViewController *masterViewController;
@property (nonatomic, strong) DkTDocket *docket;
@property (nonatomic, strong) UIButton *docketButton;

-(void) toggleButtonVisibility;

@end

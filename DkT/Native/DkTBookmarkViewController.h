
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DkTBookmarkManager.h"
#import "PACERClient.h"


@interface DkTBookmarkViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DkTBookmarkManagerDelegate, PACERClientProtocol, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) DkTBookmarkManager *bookmarkManager;
@property (nonatomic, strong) NSMutableArray *bookmarks;
@property (nonatomic, strong) UILabel *noDocumentLabel;

-(void) updateAllBookmarks;
-(void) setup;

-(void) handleSavedDocket:(DkTDocket *)docket entries:(NSArray *)entries;
-(BOOL) connectivityStatus;

@end

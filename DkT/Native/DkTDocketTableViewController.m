
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSingleton.h"
#import "DkTDetailViewController.h"
#import "UIImage+Utilities.h"
#import "UIResponder+FirstResponder.h"
#import "UIView+Utilities.h"
#import "UIViewController+MJPopupViewController.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "DkTLoginViewController.h"
#import "ReaderViewController.h"
#import "DkTSpecificDocumentViewController.h"
#import "DkTDocketViewController.h"
#import "DkTDocketEntry.h"
#import "DkTNumberedCell.h"
#import "DkTDownload.h"
#import "DkTSession.h"
#import "DkTUser.h"
#import "FSButton.h"
#import "DkTAlertView.h"
#import "PKRevealController.h"
#import "MBProgressHUD.h"
#import "DkTImageCache.h"
#import "DkTDocketPrinter.h"

typedef enum {
    DkTToolbarInfoVisible          = -1,
    DkTToolbarButtonsVisible     = 0,
    DkTToolbarDownloadProgressVisible = 1
} DkTToolbarVisibility;

typedef enum {
    DkTTableViewSelectionModeNone = 0,
    DkTTableViewSelectionBatch,
    DkTTableViewSelectionEmail,
} DkTTableViewSelectionMode;

@interface DkTDocketTableViewController () {

}

@property (nonatomic) DkTTableViewSelectionMode mode;
@property (nonatomic) NSInteger expandedRow;
@property (nonatomic) CGFloat expandedHeight;
@property (nonatomic, strong) UITableViewCell *expandedCell;
@property (nonatomic) UISwipeGestureRecognizerDirection direction;
@property (nonatomic) NSInteger completedDownloads;
@property (nonatomic, strong) DkTDocketEntry *activeEntry;
@property (nonatomic, strong) DkTDownload *batchDownload;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UIBarButtonItem *actionBarButtonItem;
@property (nonatomic, strong) NSMutableArray *filteredEntries;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIView *batchDownloadView;
@property (nonatomic, strong) UIView *docketInfoView;
@property (nonatomic, strong) UILabel *lastUpdated;
@property (nonatomic, strong) UIActivityViewController *activityController;
@property (nonatomic, strong) UIPopoverController *actionPopoverController;

@end

@implementation DkTDocketTableViewController

- (id)init{
    
    self = [super init];
    if (self) {
        self.contentSizeForViewInPopover = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ?  CGSizeMake(320.0, 600.0) : CGSizeMake(300.0, 600.0);
        self.root = YES; self.local = NO; self.completedDownloads = 0; self.expandedRow = -1; self.mode = DkTTableViewSelectionModeNone;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BOOL reverse = [[[DkTSettings sharedSettings] valueForKey:DkTSettingsMostRecentKey] boolValue];
    if(reverse) self.docketEntries = [[self.docketEntries reverseObjectEnumerator] allObjects];
   
    self.navigationController.navigationBarHidden = NO; self.navigationController.toolbarHidden = NO;
    self.view.clipsToBounds = NO;
    self.filteredEntries = [self.docketEntries mutableCopy];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    IOS7(self.tableView.separatorInset = UIEdgeInsetsZero;, );
    self.tableView.delegate = self; self.tableView.dataSource = self;
    
    [self toggleProgressLabel:DkTToolbarInfoVisible];
    [self configureTableView];
    [self.view addSubview:self.tableView];
    [self setupButtons];
}


-(void) viewDidAppear:(BOOL)animated
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && !self.isBeingPresented)
    {
         [self.tableView setFrame:CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, 290, self.tableView.frame.size.height)];
         //[self.searchBar setFrame:CGRectMake(self.searchBar.frame.origin.x, self.searchBar.frame.origin.y, 280, self.searchBar.frame.size.height)];
    }
    
    CGRect frame = self.tableView.frame; frame.size.height = self.view.frame.size.height; self.tableView.frame = frame;
    
    
    
    if(self.local){
        
        __weak DkTDocketTableViewController *weakSelf = self;
        
        BOOL reverse = [[[DkTSettings sharedSettings] valueForKey:DkTSettingsMostRecentKey] boolValue];
        
        [self.tableView addPullToRefreshWithActionHandler:^{
            
            if([weakSelf connectivityStatus]) {
                
                PACERClient *client = [PACERClient sharedClient];
                [client retrieveDocket:weakSelf.docket sender:weakSelf to:[client pacerDateString:[NSDate date]] from:weakSelf.docket.updated];
                weakSelf.lastUpdated.text = @"Updating...";
            }
            
            else [weakSelf.tableView.pullToRefreshView stopAnimating];
            
            
        } position:reverse ? SVPullToRefreshPositionTop : SVPullToRefreshPositionBottom];
        
        self.tableView.pullToRefreshView.textColor = [UIColor activeColor];
        self.tableView.pullToRefreshView.arrowColor = [UIColor activeColor];
        self.tableView.pullToRefreshView.activityIndicatorViewColor = [UIColor activeColor];
        
        [self.tableView.pullToRefreshView setTitle:@"Pull to refresh docket." forState:SVPullToRefreshStateStopped];
        [self.tableView.pullToRefreshView setSubtitle:@"PACER account will be charged for updates." forState:SVPullToRefreshStateStopped];
        [self.tableView.pullToRefreshView setTitle:@"Refreshing docket..." forState:SVPullToRefreshStateLoading];
        [self.tableView.pullToRefreshView setSubtitle:@"PACER account will be charged for updates." forState:SVPullToRefreshStateLoading];
    }
}

-(UILabel *) titleLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:self.navigationController.navigationBar.frame];
    label.text = self.title;
    label.numberOfLines = 1;
    label.textColor = [UIColor inactiveColor];
    label.font = [UIFont fontWithName:kMainFont size:PAD_OR_POD(13, 12)];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        label.text = [label.text stringByAppendingString:@"    "];
        if(!self.isLocal) label.text = [label.text stringByAppendingString:@"    "];
    }
    [label sizeToFit];
    
    return label;
}

-(void) viewWillDisappear:(BOOL)animated
{
    //[[SecondaryClient sharedClient] cancelAllHTTPOperationsWithMethod:@"POST" path:@"query/"];
    [[DkTDownloadManager sharedManager] setDelegate:nil];
    [[UIMenuController sharedMenuController] setMenuItems:nil];
    
}

-(void) bookmarkDocket
{
    NSArray *entries = self.docketEntries;
    
    if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsMostRecentKey] boolValue])
    {
        entries = [[self.docketEntries reverseObjectEnumerator] allObjects];
    }
    
    [[DkTBookmarkManager sharedManager] bookmarkDocket:self.docket withDocketEntries:entries];
}

-(BOOL) canBecomeFirstResponder { return YES; }

#pragma mark = Batch Downloading

-(void) activateDownload
{
    if(self.mode == DkTTableViewSelectionBatch)
    {
        [self dismissDownload];
        return;
    }
    
    if([[PACERClient sharedClient] checkNetworkStatusWithAlert:YES])
    {
        self.mode = DkTTableViewSelectionBatch;
        self.tableView.allowsMultipleSelection = YES;
        [self toggleProgressLabel:DkTToolbarButtonsVisible];
    }
  
}

-(void) dismissDownload
{
    [self toggleProgressLabel:DkTToolbarInfoVisible];
    for(NSIndexPath *i in self.tableView.indexPathsForSelectedRows) [self.tableView deselectRowAtIndexPath:i animated:NO];
    self.mode = DkTTableViewSelectionModeNone;
    self.tableView.allowsMultipleSelection = NO;
    [[DkTDownloadManager sharedManager] setDelegate:nil];
}

-(void) performBatchDownload
{
    if(self.tableView.indexPathsForSelectedRows.count == 0)
    {
        [self dismissDownload];
        return;
    }
    
    NSMutableArray *entries = [NSMutableArray array];
    
    for(NSIndexPath *i in self.tableView.indexPathsForSelectedRows)
    {
        DkTDocketEntry *e = [self.docketEntries objectAtIndex:i.row];
        if(![e.urls objectForKey:LocalURLKey]) [entries addObject:e];
    }
    
    if((entries.count > 0) && [self connectivityStatus])
    {
        [[DkTDownloadManager sharedManager] setDelegate:self];
        
        self.batchDownload = nil;
        __weak DkTDocketTableViewController *weakSelf = self;
        
        self.batchDownload = [[DkTDownload alloc] initWithCompletionBlock:^(DkTDownload *download, DkTDownloadCompletionStatus status) {
            
            [weakSelf dismissDownload];
            [[DkTDownloadManager sharedManager] setDelegate:nil];
            
            if((status == DkTDownloadCompletionStatusPartial) || (status == DkTDownloadCompletionStatusError))
            {
                DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Error Downloading" andMessage:@"Error downloading some documents.  Some documents may be under seal."];
                
                [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                    
                    [alertView dismissAnimated:YES];
                }];
                
                [alertView show];
            }
        }];
        
        [[DkTDownloadManager sharedManager] setBatchDownload:self.batchDownload];
        
        [self toggleProgressLabel:DkTToolbarDownloadProgressVisible];
        self.progressLabel.text = [NSString stringWithFormat:@"0 out of %lu complete.", (unsigned long)entries.count];
        
        [self.batchDownload addEntries:entries completionBlock:^(DkTDownload *download, DkTDownloadCompletionStatus status) {
            
            download.parent.completedChildren++;
            
            NSInteger completed = download.parent.completedChildren;
            NSInteger total = download.parent.children.count;
            
            weakSelf.progressLabel.text = [NSString stringWithFormat:@"%ld out of %ld complete.", (long)completed, (long)total];
            NSInteger idx = [weakSelf.filteredEntries indexOfObject:download.entry];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            
            if( (status == DkTDownloadCompletionStatusComplete) && (download.children.count == 0))
                dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView cellForRowAtIndexPath:indexPath].accessoryView = [weakSelf savedImage];
            });
            
            if(completed == total) [download.parent updateCompletionStatus];
            
        }];
        
        [DkTDownloadManager batchDownload:self.docket entries:entries sender:self];
        
        for(NSIndexPath *i in self.tableView.indexPathsForSelectedRows) [self.tableView deselectRowAtIndexPath:i animated:NO];
        self.mode = DkTTableViewSelectionModeNone;
        self.tableView.allowsMultipleSelection = NO;
    }
    
    else [self dismissDownload];
    
    
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DkTDocketEntry *e = [self.filteredEntries objectAtIndex:indexPath.row];
    
    BOOL hasLink = ([e link] != nil);
    static NSString *NumberedCellIdentifier = @"NumberedCell";
    static NSString *PlainCellIdentifier = @"PlainCell";
    
    UITableViewCell *cell;
    
    if(e.entryNumber.integerValue != 0) cell = (DkTNumberedCell *)[tableView dequeueReusableCellWithIdentifier:NumberedCellIdentifier];
    else cell = [tableView dequeueReusableCellWithIdentifier:PlainCellIdentifier];

    if(cell == nil) {
    
        if(e.entryNumber.integerValue != 0) cell = [[DkTNumberedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"NumberedCell"];
        else cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"PlainCell"];
        cell.textLabel.font = [UIFont fontWithName:kLightFont size:11];
        cell.textLabel.minimumScaleFactor = .85;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor darkerTextColor];
        cell.detailTextLabel.textColor = kDateTextColor;
        cell.detailTextLabel.font = [UIFont fontWithName:kMainFont size:9];
        cell.helpText = @"Touch to load a docket entry. Press and hold to expand cell. Use two fingers to scroll to top or bottom of docket.";
        
        [cell.contentView addGestureRecognizer:[self longPress]];
        
        
    }
    
    cell.textLabel.numberOfLines = 4;
    
    if (e.entryNumber.integerValue != 0) {
        
        DkTNumberedCell *nCell = (DkTNumberedCell *)cell;
        if(!self.isRoot && [e isKindOfClass:[DKTAttachment class]])
        {
            [nCell setNumber:[NSString stringWithFormat:@"%@.%@", e.entryNumber, ((DKTAttachment *)e).attachment]];

        }
        else [nCell setNumber:[NSString stringWithFormat:@"%@", e.entryNumber]];
        
        nCell.textLabel.textColor = hasLink ? [UIColor activeColor] : [UIColor redColor];
    }
    
    
    
    
    
    __weak DkTDocketTableViewController *weakSelf = self;
    
    if(e.lookupStatus == DktEntryStatusNone)
    {
        dispatch_async(dispatch_queue_create("lookup", 0), ^{
            
            [weakSelf lookupEntry:e];
            
        });
    }
    
    cell.accessoryView = nil;
    
    if( (e.lookupStatus != DktEntryStatusNone) || (self.isLocal) ) {
        
        
        [DkTDocumentManager localPathForDocket:self.docket entry:e completion:^(id entry, id filepath) {
            
            
            DkTDocketEntry *_entry = entry;
            _entry.lookupStatus = _entry.lookupStatus | DktEntryStatusLocal;
           
            
            if([filepath length] > 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView cellForRowAtIndexPath:indexPath].accessoryView = [weakSelf savedImage];
                });
                
            }
            
            else
            {
                [e.urls removeObjectForKey:LocalURLKey];
            }
            
            //if ([[e.urls objectForKey:DkTURLKey] length] > 0) cell.accessoryView = [weakSelf SecondaryClientLabel];
            
        }];
        
    }
    
    
    cell.selectionStyle = ((e.entryNumber.intValue == 0) || !hasLink) ?  UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray;
    
    cell.textLabel.attributedText = [e renderSummary];
    cell.detailTextLabel.text = e.date;
    
    [cell.textLabel sizeToFit];
    
    
    return cell;
}

-(UILongPressGestureRecognizer *) longPress
{
    return [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
}

-(void) lookupEntry:(DkTDocketEntry *)e
{
    
    __weak DkTDocketTableViewController *weakSelf = self;
    
    if(e.entryNumber.integerValue == 0) return;
    
    if(e.urls == nil) e.urls = [NSMutableDictionary dictionary];
    
    [DkTDocumentManager localPathForDocket:self.docket entry:e completion:^(id entry, id filepath) {
        
        
        DkTDocketEntry *_entry = entry;
        _entry.lookupStatus = _entry.lookupStatus | DktEntryStatusLocal;
        
        if([filepath length] > 0)
        {
            [_entry.urls setObject:filepath forKey:LocalURLKey];
            NSUInteger idx = [weakSelf.docketEntries indexOfObject:entry];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                [weakSelf.tableView cellForRowAtIndexPath:indexPath].accessoryView = [weakSelf savedImage];
              
            });
            
        }
        
        /*else
        {
            [[SecondaryClientClient sharedClient] isDocketEntryAvailableOnSecondaryClient:_entry completion:^(id entry, id json) {
                
                //[weakSelf addSecondaryClientToEntry:entry json:json];
                
               _entry.lookupStatus = _entry.lookupStatus | DktEntryStatusSecondaryClient;
                
                
            }];
            
            
        }*/
        
    }];
}

#pragma mark - Table view delegate

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == self.expandedRow) {
        
        return self.expandedHeight;
    }
    
    else return 80.0f;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(self.mode == DkTTableViewSelectionBatch) return;
    
    
    //[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    
    DkTDocketEntry *entry = [self.filteredEntries objectAtIndex:indexPath.row];
    
    if (self.mode == DkTTableViewSelectionEmail) {
        
        if(self.activeEntry) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            return;
        }
        
        else self.activeEntry = entry;
        
        
        if(entry.entryNumber.integerValue == 0) [self emailDocketItem:entry attachmentPath:nil];
        
        else {
            DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Email Item" andMessage:@"Download attachments if available?"];
            
            [alertView addButtonWithTitle:@"YES" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                [self downloadEntry:entry cell:[tableView cellForRowAtIndexPath:indexPath]];
                
            }];
            
            [alertView addButtonWithTitle:@"NO" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                [self emailDocketItem:entry attachmentPath:nil];
                self.mode = DkTTableViewSelectionModeNone;
            }];
            
            [alertView show];
        }
        return;
    }
    
    if(entry.entryNumber.integerValue == 0) return;
    
    [self downloadEntry:entry cell:[tableView cellForRowAtIndexPath:indexPath]];
    
    return;
    
}

-(void) downloadEntry:(DkTDocketEntry *) entry cell:(UITableViewCell *)cell {
    
    if(entry.entryNumber.integerValue == 0) return;
    
    self.activeEntry = entry;
    
    NSString *path;
    
    if( (path = [entry.urls objectForKey:LocalURLKey]) ) [self didDownloadDocketEntry:entry atPath:path cost:NO];
    
    /*
     else if ( (path = [entry.urls objectForKey:DkTURLKey]) )
     {
     [self menuForIndexPath:indexPath];
     return;
     }*/
    
    else {
        
        if([self connectivityStatus])
        {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:cell.contentView animated:YES];
            hud.color = [UIColor clearColor];
            
            if(entry.link == nil) return;
            
            [[PACERClient sharedClient] retrieveDocument:entry sender:self docket:self.docket];
            
        }
        
    }

}
/*
-(void) menuForIndexPath:(NSIndexPath *)indexPath
{
    DkTDocketEntry *entry = [self.docketEntries objectAtIndex:indexPath.row];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    [self.view becomeFirstResponder];

    
    __weak DkTDocketTableViewController *weakSelf = self;
    
    PSMenuItem *secondary = [[PSMenuItem alloc] initWithTitle:@"[secondary client]" block:^{
        
        if([[PACERClient sharedClient] checkNetworkStatusWithAlert:YES])
        {
            UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:indexPath];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:cell.contentView animated:YES];
            hud.color = [UIColor clearColor];
            [[SecondaryClient sharedClient] getDocument:entry sender:weakSelf];
        }
        
        
    }];
    
    PSMenuItem *pacer = [[PSMenuItem alloc] initWithTitle:@"PACER" block:^{
        
        if([weakSelf connectivityStatus])
        {
            UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:indexPath];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:cell.contentView animated:YES];
            hud.color = [UIColor clearColor];
            [[PACERClient sharedClient] retrieveDocument:entry sender:weakSelf docket:weakSelf.docket];
        }
    }];
    
    [pacer cxa_setFont:[UIFont fontWithName:kSecondaryFont size:9] forTitle:pacer.title];
    [secondary cxa_setFont:[UIFont fontWithName:kSecondaryFont size:9] forTitle:secondary.title];
    
    [menu setMenuItems:@[secondary, pacer]];
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    [menu setTargetRect:rect inView:self.tableView];
    [menu setMenuVisible:YES];
}*/


#pragma mark - PACER/SecondaryClient/DktDownloadManager Protocol
-(void) handleFailedConnection {
    
    self.lastUpdated.text =  [NSString stringWithFormat:@"Updated %@", self.docket.updated];
    [self.tableView.pullToRefreshView stopAnimating];
    
}

-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path
{
    [self didDownloadDocketEntry:entry atPath:path cost:YES];
}

-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path cost:(BOOL)paid
{
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.filteredEntries indexOfObject:entry] inSection:0]];
    [MBProgressHUD hideAllHUDsForView:cell.contentView animated:YES];
    //handle a downloaded document
    //path: local path of the file
    //entry: a docket entry object corresponding to the docket entry
    
    //Case One: E-mailing docket entry with attachment
    if(self.mode == DkTTableViewSelectionEmail && self.activeEntry == entry) {
        self.activeEntry = nil;
        [self emailDocketItem:entry attachmentPath:path];
        self.mode = DkTTableViewSelectionModeNone;
        return;
    }
    
    //Case Two: Anything else
    if(self.activeEntry == entry)
    {
        self.activeEntry = nil;
        ReaderDocument *readerDocument = [[ReaderDocument alloc] initWithFilePath:path password:nil];
        
        if(readerDocument == nil)
        {
            DkTAlertView *alert = [[DkTAlertView alloc] initWithTitle:@"Error" andMessage:@"Error loading document."];
            
            [alert addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                
                [alertView dismissAnimated:YES];
            }];
            
            [alert show];
            
            return;
        }
        
        ReaderViewController *pdfReader = [[ReaderViewController alloc] initWithReaderDocument:readerDocument];
        
        //PACER Opinions are free.
        //If the first word of the entry is not equal to OPINION, then we must add its cost;
        /*
         if(paid)
         {
         if(![[[entry.summary componentsSeparatedByString:@" "] objectAtIndex:0] isEqualToString:@"OPINION"])
         {
         dispatch_async(dispatch_queue_create("cost.queue", NULL), ^{
         [DkTSession addCostForPages:readerDocument.pageCount.intValue];
         });
         }
         }*/
        
        
        pdfReader.view.frame = self.detailViewController.view.frame;
        for(UIViewController *vc in self.detailViewController.childViewControllers)
        {
            [vc removeFromParentViewController];
            [vc.view removeFromSuperview];
        }
        
        self.detailViewController.title = [NSString stringWithFormat:@"Entry #%@", entry.entryString];
        [self.detailViewController addChildViewController:pdfReader];
        [self.detailViewController.view addSubview:pdfReader.view];
        [self.detailViewController setDocketEntry:entry];
        [self.detailViewController setFilePath:path];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            PKRevealController *revealController = self.parentViewController.revealController;
            [revealController showViewController:revealController.frontViewController animated:YES completion:^(BOOL finished) {
            
                [revealController.revealResetTapGestureRecognizer requireGestureRecognizerToFail:pdfReader.singleTap];
            
            }];
        }
    }
    
}

-(void) handleDocumentsFromDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry entries:(NSArray *)entries
{
    if(self.mode == DkTTableViewSelectionEmail && self.activeEntry == entry) {
        [self emailDocketItem:entry attachmentPath:nil];
        self.mode = DkTTableViewSelectionModeNone;
        self.activeEntry = nil;
        return;
    }
    
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.filteredEntries indexOfObject:entry] inSection:0]];
    [MBProgressHUD hideAllHUDsForView:cell.contentView animated:YES];
    
    DkTDocketTableViewController *nextController = [[DkTDocketTableViewController alloc] init];
    nextController.title = [NSString stringWithFormat:@"Entry #%@", entry.entryString];
    nextController.docketEntries = entries;
    nextController.root = NO;
    nextController.docket = self.docket;
    nextController.detailViewController = self.detailViewController;
    
    [self.navigationController pushViewController:nextController animated:YES];
}

-(void) handleSealedDocument:(DkTDocketEntry *)entry
{
    self.mode = DkTTableViewSelectionModeNone;
    self.activeEntry = nil;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.filteredEntries indexOfObject:entry] inSection:0]];
    
    [MBProgressHUD hideAllHUDsForView:cell.contentView animated:YES];
    
    for(UIViewController *vc in self.detailViewController.childViewControllers)
    {
        [vc removeFromParentViewController];
        [vc.view removeFromSuperview];
    }

    DkTSpecificDocumentViewController *sealedVC = [[DkTSpecificDocumentViewController alloc] initWithType:DkTSealedDocumentViewControllerType];
    sealedVC.entry = entry;
    
    [self.detailViewController addChildViewController:sealedVC];
    [self.detailViewController.view addSubview:sealedVC.view];
    [self.detailViewController setDocketEntry:entry];
    [self.detailViewController setFilePath:nil];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) [self.parentViewController.revealController showViewController:self.parentViewController.revealController.frontViewController animated:YES completion:^(BOOL finished) {
        
    }];
}

-(void) handleDocketEntryError:(DkTDocketEntry *)entry
{
    self.activeEntry = nil;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.filteredEntries indexOfObject:entry] inSection:0]];
    [MBProgressHUD hideAllHUDsForView:cell.contentView animated:YES];
    
    
    for(UIViewController *vc in self.detailViewController.childViewControllers)
    {
        [vc removeFromParentViewController];
        [vc.view removeFromSuperview];
    }
    
    DkTSpecificDocumentViewController *errorVC = [[DkTSpecificDocumentViewController alloc] initWithType:DkTErrorDocumentViewControllerType];
    errorVC.entry = entry;
    [self.detailViewController addChildViewController:errorVC];
    [self.detailViewController.view addSubview:errorVC.view];
    [self.detailViewController setDocketEntry:entry];
    [self.detailViewController setFilePath:nil];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) [self.parentViewController.revealController showViewController:self.parentViewController.revealController.frontViewController animated:YES completion:^(BOOL finished) {
        
    }];
}

-(void) handleDocketError:(DkTDocket *)docket { [self handleFailedConnection]; }
-(void) handleDocket:(DkTDocket *)docket entries:(NSArray *)entries to:(NSString *)to from:(NSString *)from
{
    DkTBookmarkManager *manager = [DkTBookmarkManager sharedManager];
    [manager appendEntries:entries toSavedDocket:docket];
    self.docketEntries = [manager savedDocket:docket];
    BOOL reverse = [[[DkTSettings sharedSettings] valueForKey:DkTSettingsMostRecentKey] boolValue];
    if(reverse) self.docketEntries = [[self.docketEntries reverseObjectEnumerator] allObjects];
    [self filterContentForSearch:self.searchBar.text];
    self.lastUpdated.text =  [NSString stringWithFormat:@"Updated %@", self.docket.updated];
    [self.tableView.pullToRefreshView stopAnimating];
    [self.tableView reloadData];
}


-(BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
    
    NSString *selectorString = NSStringFromSelector(action);
    
    return ([selectorString rangeOfString:@"ps_"].location != NSNotFound);
 
}

-(void) handleDocLink:(DkTDocketEntry *)entry docLink:(NSString *)docLink
{
    
    if( ([entry.urls objectForKey:DkTURLKey] == nil) && ([entry.urls objectForKey:DkTURLKey] == nil))
    {
        /*
        [[SecondaryClient sharedClient] isDocketEntryAvailableOnSecondaryClient:entry completion:^(id e, id json) {
            
            [self addSecondaryClientToEntry:e json:json];
            
        }];*/
    }
}

/*

-(void) addSecondaryClientToEntry:(DkTDocketEntry *)entry json:(NSDictionary *)json
{
    NSDictionary *filenameDict = [[json allValues] lastObject];
    
    if(filenameDict)
    {
        NSString *filename = [filenameDict objectForKey:@"filename"];
        
        if(filename.length > 0)
        {
            [entry.urls setObject:[filenameDict objectForKey:@"filename"] forKey:DkTURLKey];
            NSInteger row = [self.docketEntries indexOfObject:entry];
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:row inSection:0];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
                
            });
        }
        
    }
    
}*/

-(void) configureTableView
{
    self.tableView.decelerationRate = 0.5;
    self.tableView.clipsToBounds = NO;
    self.tableView.allowsMultipleSelection = NO;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | PAD_OR_POD(UIViewAutoresizingFlexibleWidth, UIViewAutoresizingNone);
    self.tableView.scrollEnabled = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    UISwipeGestureRecognizer *doubleSwipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleSwipeUp:)];
    doubleSwipeUp.numberOfTouchesRequired = 2;
    doubleSwipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    doubleSwipeUp.delegate = self;
    [self.tableView addGestureRecognizer:doubleSwipeUp];
    
    UISwipeGestureRecognizer *doubleSwipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleSwipeDown:)];
    doubleSwipeDown.numberOfTouchesRequired = 2;
    doubleSwipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    doubleSwipeDown.delegate = self;
    [self.tableView addGestureRecognizer:doubleSwipeDown];
    
    self.direction = UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight;
    
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = [UIColor clearColor];
    [self.tableView setBackgroundView:backgroundView];
    
    //[PSMenuItem installMenuHandlerForObject:self.view];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, PAD_OR_POD(self.tableView.frame.size.width, 290), 50)];
    self.searchBar.placeholder = @"Search Docket";
    self.searchBar.delegate = self;
    //self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] != 7)
    {
        [[self.searchBar.subviews objectAtIndex:0] removeFromSuperview];
        self.searchBar.backgroundColor = [UIColor lightGrayColor];
    }
    
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.contentOffset = CGPointMake(0, self.searchBar.frame.size.height);
}


-(UILabel *) SecondaryClientLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, self.tableView.rowHeight)];
    label.text = [NSString stringWithFormat:@""];
    label.font = [UIFont fontWithName:kContrastFont size:14];
    label.textColor = [UIColor activeColor];
    [label sizeToFit];
    return label;
}

-(UIImageView *) folderImage
{
    
    UIImage *image = [kFolderImage imageWithColor:[UIColor activeColor]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    return imageView;
}

-(UIImageView *) savedImage
{
    UIImage *img = [[DkTImageCache sharedCache] imageNamed:@"save" color:[UIColor activeColor]];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
    imgView.frame = CGRectMake(0, 0, 20, 20);
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    return imgView;
}


-(void) scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

-(BOOL) connectivityStatus
{
    PACERConnectivityStatus status = [PACERClient connectivityStatus];
    
    if( (status & PACERConnectivityStatusNoInternet) > 0)
    {
        DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Network Error" andMessage:@"Check Network Connection"];
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            [alertView dismissAnimated:YES];
        }];
        
        [alertView show];
        
        return FALSE;
    }
    
    else if( (status & PACERConnectivityStatusNotLoggedIn) > 0)
    {
        
        DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Error" andMessage:@"Have you logged into PACER?"];
        
        
        __block DkTLoginViewController *lvc = [self lvc];
        
        SIAlertViewHandler dismissHandler = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? ^(SIAlertView *alertView) {
            
            
            
            lvc.modalPresentationStyle = UIModalPresentationFormSheet;
            UIViewController *dvc = [UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController; //ugly, but it gets the rootViewController of the modal view
            
            [dvc presentViewController:lvc animated:YES completion:^{
                
            }];
            
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissLVC:)];
            [dvc.view.window addGestureRecognizer:tapGesture];
            lvc.view.superview.backgroundColor = [UIColor clearColor];
            //[lvc.view.superview setFrame:CGRectInset(lvc.view.superview.frame, 100, 60)];
            [lvc.view setFrame:CGRectMake(140, 160, 260, 300)];
            lvc.view.layer.cornerRadius = 5.0;
            //[lvc.view.superview setCenter:point];
            
        } :
        
        ^(SIAlertView *alertView){
            
            [self.parentViewController presentPopupViewController:lvc animationType:MJPopupViewAnimationSlideBottomTop dismissed:^{
                
            }];
            
            UIViewController *topParent = self;
            while (topParent.parentViewController != nil) {
                topParent = topParent.parentViewController;
            }
            [topParent addChildViewController:lvc];
        };
        
        alertView.didDismissHandler = dismissHandler;
        
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            
            
        }];
        
        
        [alertView show];
        return FALSE;
    }
    
    return TRUE;

}

-(void) dismissLVC:(id)sender
{
    
    UIViewController *dvc = [UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
    [dvc dismissViewControllerAnimated:YES completion:nil];
    [dvc.view.window removeGestureRecognizer:sender];
    
}


-(void) viewDidDisappear:(BOOL)animated
{
    self.batchDownload = nil;
}

#pragma mark search methods
-(void) filterContentForSearch:(NSString *)text
{
    if(text.length == 0)
    {
        self.filteredEntries = [self.docketEntries mutableCopy];
        return;
    }
    [self.filteredEntries removeAllObjects];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF.summary contains[c] %@", text];
    self.filteredEntries = [NSMutableArray arrayWithArray:[_docketEntries filteredArrayUsingPredicate:pred]];
}


-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    
    [self filterContentForSearch:searchBar.text];
    self.expandedRow = -1;
    self.expandedCell.textLabel.numberOfLines = 4;
    self.expandedCell = nil;
    [self.tableView reloadData];
   
}


#pragma mark User Interface

-(void) setupButtons
{
    
    CGRect bbFrame = CGRectMake(0, 0, kToolbarIconSize.width*.9, kToolbarIconSize.height*.9);
    UIImage *docketImage = [[DkTImageCache sharedCache] imageNamed:@"grid" color:[UIColor inactiveColor]];
    UIImage *bookmarkImage = [kBookmarkImage imageWithColor:[UIColor inactiveColor]];
    UIImage *backImage = [[DkTImageCache sharedCache] imageNamed:@"back" color:[UIColor inactiveColor]];
    
    UIButton *backBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backBarButton.frame = bbFrame;
    [backBarButton setBackgroundImage:backImage forState:UIControlStateNormal];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backBarButton];
    self.navigationItem.leftBarButtonItem = backBarButtonItem;
    
    //Action Button
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame = bbFrame;
    [actionButton setBackgroundImage:docketImage forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(handleAction:) forControlEvents:UIControlEventTouchUpInside];
    self.actionBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
    actionButton.helpText = @"Open action menu.";
    
    //Bookmark button
    
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    space.width = 30;
    
    if([self isRoot] && ![self isLocal])
    {
        UIButton *bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        bookmarkButton.frame = bbFrame;
        [bookmarkButton setBackgroundImage:bookmarkImage forState:UIControlStateNormal];
        [bookmarkButton addTarget:self action:@selector(bookmarkDocket) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *bookmarkBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:bookmarkButton];
        bookmarkButton.helpText = @"Bookmark the docket.";
        self.navigationItem.rightBarButtonItems = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @[self.actionBarButtonItem, bookmarkBarButtonItem] : @[space, self.actionBarButtonItem, bookmarkBarButtonItem];
    }
    
    else self.navigationItem.rightBarButtonItems =  (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @[self.actionBarButtonItem] : @[space, self.actionBarButtonItem];
  
    if(self.isRoot) self.title = @"Docket";
    
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
      //  NSString *lead = self.isLocal ? @"        " : @"    ";
      //  self.title = [lead stringByAppendingString:self.title];
    }
    
    
    self.navigationItem.titleView = [self titleLabel];
    self.navigationController.toolbarHidden = NO;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) self.navigationController.view.autoresizesSubviews = NO;
    
    
    
    if(!self.isRoot)
    {
        self.navigationItem.hidesBackButton = YES;
        [backBarButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    else
    {
        [backBarButton addTarget:self.parentViewController.presentingViewController action:@selector(dismissModalViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(UIView *)docketInfoView
{
    if(_docketInfoView == nil)
    {
      //  _docketInfoView = [[UIView alloc] initWithFrame:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? self.navigationController.toolbar.bounds : CGRectMake(0, 0, self.contentSizeForViewInPopover.width, self.navigationController.toolbar.bounds.size.height)];
        _docketInfoView = [[UIView alloc] initWithFrame:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? self.navigationController.toolbar.bounds : CGRectMake(0, 0, self.contentSizeForViewInPopover.width, self.navigationController.toolbar.bounds.size.height)];
        //_docketInfoView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        CGFloat compensator = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 0 : 20;
        
        if(self.docket.updated.length > 0 && self.local)
        {
            self.lastUpdated = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, _docketInfoView.frame.size.width-compensator, 13)];
            self.lastUpdated.backgroundColor = [UIColor clearColor];
            self.lastUpdated.font = [UIFont fontWithName:kMainFont size:10];
            self.lastUpdated.textColor = [UIColor inactiveColor];
            self.lastUpdated.textAlignment = NSTextAlignmentCenter;
            self.lastUpdated.text =  [NSString stringWithFormat:@"Updated %@", self.docket.updated];
            [_docketInfoView addSubview:self.lastUpdated];
        }
        
    }
    return _docketInfoView;
}

-(UIView *)batchDownloadView
{
    if(_batchDownloadView == nil)
    {
        _batchDownloadView = [[UILabel alloc] initWithFrame:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? self.navigationController.toolbar.bounds : CGRectMake(0, 0, self.contentSizeForViewInPopover.width, self.navigationController.toolbar.bounds.size.height)];
        _batchDownloadView.backgroundColor = [UIColor clearColor];
        _batchDownloadView.userInteractionEnabled = YES;
        __weak DkTDocketTableViewController *weakSelf = self;
        
        FSButton *downloadBatchButton = [FSButton buttonWithIcon:nil colors:@[[UIColor inactiveColor], [UIColor activeColor]] title:@"OK" actionBlock:^{
            [weakSelf performBatchDownload];
        }];
        
        downloadBatchButton.frame = CGRectMake(self.contentSizeForViewInPopover.width*.1, self.navigationController.toolbar.frame.size.height*.1, self.contentSizeForViewInPopover.width*.3, self.navigationController.toolbar.frame.size.height*.8);
        downloadBatchButton.helpText = @"Download a batch of documents. Select docket entries from the docket and press OK to download.";
        downloadBatchButton.layer.cornerRadius = 5.0;
        
        FSButton *cancelBatchButton = [FSButton buttonWithIcon:nil colors:@[[UIColor inactiveColor], [UIColor activeColor]] title:@"Cancel" actionBlock:^{
            [weakSelf dismissDownload];
        }];
        
        cancelBatchButton.frame = CGRectMake(self.contentSizeForViewInPopover.width*.6, self.navigationController.toolbar.frame.size.height*.1, self.contentSizeForViewInPopover.width*.3, self.navigationController.toolbar.frame.size.height*.8);
        
        cancelBatchButton.layer.cornerRadius = 5.0;
        
        [_batchDownloadView addSubview:downloadBatchButton];
        [_batchDownloadView addSubview:cancelBatchButton];
    }
    
    return _batchDownloadView;
}

-(UILabel *)progressLabel
{
    if(_progressLabel == nil)
    {
        _progressLabel = [[UILabel alloc] initWithFrame:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? self.navigationController.toolbar.bounds : CGRectMake(0, 0, self.contentSizeForViewInPopover.width, self.navigationController.toolbar.bounds.size.height)];
        _progressLabel.numberOfLines = 1;
        _progressLabel.textColor = [UIColor inactiveColor];
        _progressLabel.font = [UIFont fontWithName:kMainFont size:13];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.backgroundColor = [UIColor clearColor];
    }
    
    return _progressLabel;
}

-(void) toggleProgressLabel:(DkTToolbarVisibility)visibility
{
    
    UIToolbar *toolbar = self.navigationController.toolbar;
    
    for(UIView *subview in toolbar.subviews)
    {
        [subview removeFromSuperview];
    }

    if(visibility == DkTToolbarInfoVisible) [toolbar addSubview:self.docketInfoView];
    
    else if(visibility == DkTToolbarButtonsVisible)[toolbar addSubview:self.batchDownloadView];
    
    else if(visibility == DkTToolbarDownloadProgressVisible) [toolbar addSubview:self.progressLabel];
    
}

-(DkTLoginViewController *)lvc
{
    
    DkTLoginViewController *lvc = [[DkTLoginViewController alloc] init];
    
    CGRect frame = self.view.frame;
    frame.size.height = 270; frame.size.width *= .75; lvc.view.frame = frame;
    lvc.view.autoresizingMask = UIViewAutoresizingNone;
    lvc.view.layer.cornerRadius = 5.0;
    lvc.view.center = self.view.center;
    lvc.view.layer.shadowRadius = 8.;
    lvc.view.opaque = NO;
    lvc.modal = YES;
    
    return lvc;
}

#pragma mark - Gesture Handling


-(void) scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    
    if(self.direction == UISwipeGestureRecognizerDirectionUp)  [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height) animated:NO];
    
    else if (self.direction == UISwipeGestureRecognizerDirectionDown) [self.tableView setContentOffset:CGPointMake(0, self.searchBar.frame.size.height) animated:NO];
    
}

-(void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
    if(self.direction == UISwipeGestureRecognizerDirectionUp || self.direction == UISwipeGestureRecognizerDirectionDown)
        self.direction = UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight;
}

-(void) handleDoubleSwipeUp:(UISwipeGestureRecognizer *)sender { self.direction = UISwipeGestureRecognizerDirectionUp; }

-(void) handleDoubleSwipeDown:(UISwipeGestureRecognizer *)sender { self.direction = UISwipeGestureRecognizerDirectionDown; }

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return YES;
}

-(void) handleLongPress:(UIGestureRecognizer *)sender
{
    if(sender.state == UIGestureRecognizerStateBegan)
    {
        UIView *view = [sender view];
        UIView *superview = [view superview];
        
        while (![superview isKindOfClass:[UITableViewCell class]]) {
            superview = [superview superview];
        };
        
        
        UITableViewCell *cell = (UITableViewCell *)superview;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        if(self.expandedCell)
        {
            self.expandedCell.textLabel.numberOfLines = 4;
            [self.expandedCell setNeedsDisplay];
        }
        
        self.expandedCell = nil;
        
        if(self.expandedRow == indexPath.row) self.expandedRow = -1;
        
        else
        {
            self.expandedCell = cell;
            self.expandedRow = indexPath.row;
            self.expandedHeight = [self calculateExpandedHeight:self.expandedCell];
            self.expandedCell.textLabel.numberOfLines = 0;
            [self.expandedCell setNeedsDisplay];
        }

        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

-(CGFloat) calculateExpandedHeight:(UITableViewCell *)cell
{
    CGFloat cellHeight = cell.frame.size.height;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    DkTDocketEntry *e = [self.filteredEntries objectAtIndex:indexPath.row];
    CGFloat textWidth = cell.textLabel.frame.size.width;
    CGFloat textHeight = cell.textLabel.frame.size.height;
    NSString *text = [e.renderSummary string];
    CGSize size = [text sizeWithFont:[UIFont fontWithName:kLightFont size:11] constrainedToSize:CGSizeMake(textWidth, MAXFLOAT) lineBreakMode:NSLineBreakByTruncatingTail];
    return cellHeight + (size.height - textHeight);
}

-(void) handleAction:(id)sender {
    
    RNGridMenuItem *printItem = [[RNGridMenuItem alloc] initWithImage:[[DkTImageCache sharedCache] imageNamed:@"document" color:[UIColor inactiveColor]] title:@"PDF" action:^{
        
        NSString *path = [NSString stringWithFormat:@"%@%@.pdf", [DkTDocumentManager temporaryDocumentsDirectory],self.docket.name];
        
        [DkTDocketPrinter printDocket:self.docket entries:self.docketEntries toPath:path];
        
        ReaderDocument *readerDocument = [[ReaderDocument alloc] initWithFilePath:path password:nil];
        ReaderViewController *pdfReader = [[ReaderViewController alloc] initWithReaderDocument:readerDocument];
        pdfReader.view.frame = self.detailViewController.view.frame;
        for(UIViewController *vc in self.detailViewController.childViewControllers)
        {
            [vc removeFromParentViewController];
            [vc.view removeFromSuperview];
        }
        
        self.detailViewController.title = self.docket.name;
        [self.detailViewController addChildViewController:pdfReader];
        [self.detailViewController.view addSubview:pdfReader.view];
        [self.detailViewController setFilePath:path];
        
    }];

    
    RNGridMenuItem *emailDocketItem = [[RNGridMenuItem alloc] initWithImage:[[DkTImageCache sharedCache] imageNamed:@"mail" color:[UIColor inactiveColor]] title:@"Email Item" action:^{
        
        self.mode = DkTTableViewSelectionEmail;
    }];
    
    
    RNGridMenuItem *downloadDocketItem = [[RNGridMenuItem alloc] initWithImage:[[DkTImageCache sharedCache] imageNamed:@"docketAdd" color:[UIColor inactiveColor]] title:@"Batch" action:^{
        
        [self activateDownload];
        
    }];
    

    RNGridMenu *menu = [[RNGridMenu alloc] initWithItems:[MFMailComposeViewController canSendMail] ? @[printItem, emailDocketItem, downloadDocketItem] : @[printItem, downloadDocketItem]];
    menu.delegate = self;
    menu.blurLevel = .5;
    menu.highlightColor = [UIColor activeColorLight];
    menu.backgroundColor = [UIColor activeColor];
    [menu showInViewController:self.parentViewController center:self.parentViewController.view.center];
}

- (void)gridMenu:(RNGridMenu *)gridMenu willDismissWithSelectedItem:(RNGridMenuItem *)item atIndex:(NSInteger)itemIndex {
    
    if(itemIndex == 1) {
        DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"E-mail Docket Item" andMessage:@"Select an entry to e-mail."];
        
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            
            [alertView dismissAnimated:YES];
        }];
        
        [alertView show];

    }
    
}

-(void) emailDocketItem:(DkTDocketEntry *)entry attachmentPath:(NSString *)path {
    
    self.activeEntry = nil;
    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.filteredEntries indexOfObject:entry] inSection:0] animated:NO];
    if([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        
        
        mailVC.title = self.title;
        NSString *subject = [NSString stringWithFormat:@"%@ - %@", entry.docket.name, entry.entryNumber];
        [mailVC setMessageBody:entry.summary isHTML:YES];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSData *data = [NSData dataWithContentsOfFile:path];
            NSString *fileName = [NSString stringWithFormat:@"%@ - %@.pdf", entry.docket.name, entry.entryNumber];
            [mailVC addAttachmentData:data mimeType:@"application/pdf" fileName:fileName];
            
        }
        
        
        [mailVC setSubject:subject];
        [mailVC.navigationBar setTitleTextAttributes:@{UITextAttributeTextColor:[UIColor inactiveColor]}];
        [mailVC.navigationBar setTintColor:[UIColor inactiveColor]];
        
        
        for(UINavigationItem *i in mailVC.navigationBar.items)
        {
            
            IOS7([i.leftBarButtonItem setTintColor:[UIColor whiteColor]];
                 [i.rightBarButtonItem setTintColor:[UIColor whiteColor]];
                 [i.backBarButtonItem setTintColor:[UIColor whiteColor]];, )
            
        }
        
        mailVC.mailComposeDelegate = self;
        
        [self presentViewController:mailVC animated:YES completion:^{
            
        }];
    }
    
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end

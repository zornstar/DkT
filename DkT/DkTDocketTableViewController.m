//
//  RECAPDocketTableViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//


#import "ReaderViewController.h"
#import "UIImage+Utilities.h"
#import "PSMenuItem.h"
#import "UIMenuItem+CXAImageMenuItem.h"
#import "UIResponder+FirstResponder.h"

#import "DkTDownloadManager.h"
#import "DkTDetailViewController.h"

#import "DkTDocketViewController.h"
#import "DkTDocketTableViewController.h"
#import "DkTDocketEntry.h"
#import "DkTMultiDocSelectionViewController.h"
#import "DkTBookmarkManager.h"
#import "DkTDocumentManager.h"

#import "FSButton.h"
#import "DkTView.h"

#import <QuartzCore/QuartzCore.h>


@interface DkTDocketTableViewController ()
{
    DkTDocketEntry *_downloadingEntry;
    NSInteger _selectedRow;
}

@property (nonatomic, getter = isBatching) BOOL batching;
@property (nonatomic, getter = isDownloading) BOOL downloading;
@property (nonatomic, strong) NSArray *toolbarButtons;
@property (nonatomic, strong) UILabel *progressLabel;
@end

@implementation DkTDocketTableViewController

- (id)init{
    
    self = [super init];
    if (self) {
        self.navigationController.navigationBarHidden = YES;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        _selectedRow = NSNotFound;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureTableView];
    self.batching = NO;
    self.downloading = NO;
    
    UIImage *docketImage = [[UIImage imageNamed:@"docketAdd"] imageWithColor:kInactiveColor];
    UIImage *bookmarkImage = [kBookmarkImage imageWithColor:kInactiveColor];
    
    CGRect bbFrame = CGRectMake(0, 0, kToolbarIconSize.width, kToolbarIconSize.height);
    
    UIButton *downloadDocketButton = [UIButton buttonWithType:UIButtonTypeCustom];
    downloadDocketButton.frame = bbFrame;
    [downloadDocketButton setBackgroundImage:docketImage forState:UIControlStateNormal];
    [downloadDocketButton addTarget:self action:@selector(activateDownload) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *downloadDocketBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:downloadDocketButton];
    downloadDocketButton.helpText = @"Download multiple documents from the docket.";
    
    UIButton *bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    bookmarkButton.frame = bbFrame;
    [bookmarkButton setBackgroundImage:bookmarkImage forState:UIControlStateNormal];
    [bookmarkButton addTarget:self action:@selector(bookmarkDocket) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *bookmarkBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:bookmarkButton];
    
    self.navigationItem.rightBarButtonItem = downloadDocketBarButtonItem;
    self.navigationItem.leftBarButtonItem = bookmarkBarButtonItem;
    self.navigationItem.titleView = [self titleLabel];
    
    FSButton *downloadBatchButton = [FSButton buttonWithIcon:nil colors:@[kInactiveColor, kActiveColor] title:@"OK" actionBlock:^{
        [self performBatchDownload];
    }];
    
    downloadBatchButton.frame = CGRectMake(self.contentSizeForViewInPopover.width*.1, 0, self.contentSizeForViewInPopover.width*.3, self.navigationController.toolbar.frame.size.height);
    
    FSButton *cancelBatchButton = [FSButton buttonWithIcon:nil colors:@[kInactiveColor, kActiveColor] title:@"Cancel" actionBlock:^{
         
         if(self.isDownloading) [DkTDownloadManager terminate];
            
        [self dismissDownload];
    }];
    
    cancelBatchButton.frame = CGRectMake(self.contentSizeForViewInPopover.width*.6, 0, self.contentSizeForViewInPopover.width*.3, self.navigationController.toolbar.frame.size.height);
    
    UIBarButtonItem *batchDownloadBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:bookmarkButton];
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:bookmarkButton];
    
    self.toolbarButtons = @[batchDownloadBarButtonItem, cancelBarButtonItem];
    self.navigationController.toolbarHidden = YES;

    
}

-(UILabel *) titleLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:self.navigationController.navigationBar.frame];
    label.text = self.title;
    label.numberOfLines = 1;
    label.textColor = kInactiveColor;
    label.font = [UIFont fontWithName:kMainFont size:13];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    return label;
}

-(void) viewWillDisappear:(BOOL)animated
{
    [[RECAPClient sharedClient] cancelAllHTTPOperationsWithMethod:@"POST" path:@"query/"];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) bookmarkDocket
{
    [[DkTBookmarkManager sharedManager] bookmarkDocket:self.docket withDocketEntries:self.docketEntries];
}

#pragma mark = Batch Downloading

-(void) didFinishOperationNumber:(NSInteger)opNum total:(NSInteger)total
{
    if(opNum == total)
    {
        [self.navigationController setToolbarHidden:YES animated:YES];
        self.toolbarItems = self.toolbarButtons;
    }
    
    else
        self.progressLabel.text = [NSString stringWithFormat:@"%d out of %d complete.", opNum, total];
}

-(void) activateDownload
{
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    if(self.isDownloading == FALSE)
    {
        self.batching = YES;
        self.tableView.allowsMultipleSelection = YES;
        self.toolbarItems = self.toolbarButtons;
    }
    
}


-(void) dismissDownload
{
    [self.navigationController setToolbarHidden:YES animated:YES];
    for(NSIndexPath *i in self.tableView.indexPathsForSelectedRows) [self.tableView deselectRowAtIndexPath:i animated:NO];
    self.batching = NO;
}

-(void) performBatchDownload
{
    NSMutableArray *entries = [NSMutableArray array];
    
    for(NSIndexPath *i in self.tableView.indexPathsForSelectedRows)
    {
        [entries addObject:[self.docketEntries objectAtIndex:i.row]];
    }
    
    self.toolbarItems = nil;
    self.downloading = YES;
    
    if(_progressLabel == nil)
    {
        self.progressLabel = [[UILabel alloc] initWithFrame:[[self.toolbarButtons objectAtIndex:0] frame]];
        self.progressLabel.numberOfLines = 1;
        self.progressLabel.textColor = kInactiveColor;
        self.progressLabel.font = [UIFont fontWithName:kMainFont size:13];
        self.progressLabel.textAlignment = NSTextAlignmentCenter;
        self.progressLabel.backgroundColor = [UIColor clearColor];
    }
    
    self.progressLabel.text = [NSString stringWithFormat:@"0 out of %d complete.", entries.count];
    
    UIBarButtonItem *progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.progressLabel];
    
    self.toolbarItems = @[progressBarButtonItem, [self.toolbarItems objectAtIndex:1]];
    
    [DkTDownloadManager batchDownload:self.docket entries:entries sender:self];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.docketEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DkTDocketEntry *entry = [self.docketEntries objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont fontWithName:kLightFont size:11];
        cell.textLabel.numberOfLines = 4;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = kDarkTextColor;
        cell.detailTextLabel.textColor = kDateTextColor;
        cell.detailTextLabel.font = [UIFont fontWithName:kMainFont size:9];
        
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
    }
    
    
    UIImage *img = (entry.entry != 0) ? [UIImage imageWithString:[NSString stringWithFormat:@"%d",entry.entry]
                                                            font:[UIFont fontWithName:kMainFont size:12]
                                                            size:CGSizeMake(30, 30)
                                                           color:kInactiveColor
                                                 backgroundColor:kActiveColor]
    : nil;
    if(img)
    {
        cell.imageView.image = img;
        cell.imageView.layer.cornerRadius = 4.0;
    }
    
    
    if(entry.lookupFlag) {
        
        if([entry.urls objectForKey:LocalURLKey]) {
            
            cell.accessoryView = [self folderImage];
            
        }
        
        else if ([entry.urls objectForKey:DkTURLKey]) {
            
            
            cell.accessoryView = [self RECAPLabel];
        }
        
        else {
            cell.accessoryView = nil;
        }
    }
    
    else {
        
        dispatch_async(dispatch_queue_create("lookup", 0), ^{
           
            [self lookupEntry:entry];
        
        });
        
        
    }
    
    
    
    cell.textLabel.attributedText = [entry renderSummary];
    cell.detailTextLabel.text = entry.date;
    
    [cell.textLabel sizeToFit];
    
    
    return cell;
}

-(void) lookupEntry:(DkTDocketEntry *)e
{
    if(e.urls == nil) e.urls = [NSMutableDictionary dictionary];
    
    [DkTDocumentManager localPathForDocket:self.docket entry:e completion:^(id entry, id filepath) {
        
        
        DkTDocketEntry *_entry = entry;
        
        if(filepath)
        {
            [_entry.urls setObject:filepath forKey:LocalURLKey];
            NSUInteger idx = [self.docketEntries indexOfObject:entry];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                [self.tableView cellForRowAtIndexPath:indexPath].accessoryView = [self RECAPLabel];
              
            });
            
            _entry.lookupFlag = TRUE;
        }
        
        else
        {
            [[RECAPClient sharedClient] isDocketEntryRECAPPED:_entry completion:^(id entry, id json) {
                
                [self addRecapToEntry:entry json:json];
                
                _entry.lookupFlag = TRUE;
                
            }];
            
        }
        
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(self.isBatching) return;
    
    DkTDocketEntry *entry = [self.docketEntries objectAtIndex:indexPath.row];
    
    NSString *path;
    
    if( (path = [entry.urls objectForKey:LocalURLKey]) )
    {
        [self didDownloadDocketEntry:entry atPath:path cost:NO];
    }
    
    else if ( (path = [entry.urls objectForKey:DkTURLKey]) )
    {
        [self menuForIndexPath:indexPath];
        return;
    }
    
    else {
        
        [[PACERClient sharedClient] getDocument:entry sender:self];
    }
    return;
    
}


-(void) menuForIndexPath:(NSIndexPath *)indexPath
{
    DkTDocketEntry *entry = [self.docketEntries objectAtIndex:indexPath.row];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    [self.view becomeFirstResponder];

    PSMenuItem *recap = [[PSMenuItem alloc] initWithTitle:@"RECAP" block:^{
        
        [[RECAPClient sharedClient] getDocument:entry sender:self];
        
    }];
    
    PSMenuItem *pacer = [[PSMenuItem alloc] initWithTitle:@"PACER" block:^{
        
        [[PACERClient sharedClient] getDocument:entry sender:self];
    }];
    
    [pacer cxa_setFont:[UIFont fontWithName:kMainFont size:9] forTitle:pacer.title];
    [recap cxa_setFont:[UIFont fontWithName:kMainFont size:9] forTitle:recap.title];
    
    
    [PSMenuItem installMenuHandlerForObject:self.tableView];
    [menu setMenuItems:@[recap, pacer]];
    menu.arrowDirection = UIMenuControllerArrowDown;
    
    CGFloat width =  self.detailViewController.contentSizeForViewInPopover.width;
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
   // rect.origin.y -= self.tableView.contentOffset.y;
    rect.size.width = width;

        [menu setTargetRect:rect inView:self.tableView];
        [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
}


#pragma mark - PACER/RECAP Protocol

-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path
{
    [self didDownloadDocketEntry:entry atPath:path cost:YES];
}

-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path cost:(BOOL)paid
{
    //handle a downloaded document
    
    //path: local path of the file
    //entry: a docket entry object corresponding to the docket entry
    
    
    NSLog(@"%@",path);
    ReaderDocument *readerDocument = [[ReaderDocument alloc] initWithFilePath:path password:nil];
    ReaderViewController *pdfReader = [[ReaderViewController alloc] initWithReaderDocument:readerDocument];
    
    //PACER Opinions are free.
    //If the first word of the entry is not equal to OPINION, then we must add its cost;
    if(paid)
    {
        if(![[[entry.summary componentsSeparatedByString:@" "] objectAtIndex:0] isEqualToString:@"OPINION"])
        {
            dispatch_async(dispatch_queue_create("cost.queue", NULL), ^{
                
            });
        }
    }
    
    pdfReader.view.frame = self.detailViewController.view.frame;
    for(UIViewController *vc in self.detailViewController.childViewControllers)
    {
        [vc removeFromParentViewController];
        [vc.view removeFromSuperview];
    }
    
    [self.detailViewController addChildViewController:pdfReader];
    [self.detailViewController.view addSubview:pdfReader.view];
    [self.detailViewController setDocketEntry:entry];
    [self.detailViewController setFilePath:path];
    
    
}

-(void) handleMultidocRequest:(DkTDocketEntry *)entry entries:(NSArray *)entries
{
    [DkTMultiDocSelectionViewController presentAsPopover:self size:CGSizeMake(240, 480) choices:entries];
}

-(BOOL) canBecomeFirstResponder
{
    return YES;
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
        [[RECAPClient sharedClient] isDocketEntryRECAPPED:entry completion:^(id e, id json) {
            
            [self addRecapToEntry:e json:json];
            
        }];
    }
}

-(void) addRecapToEntry:(DkTDocketEntry *)entry json:(NSDictionary *)json
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
    
}

-(void) configureTableView
{
    self.tableView.allowsMultipleSelection = NO;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.tableView.rowHeight = 80;
    self.tableView.scrollEnabled = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = [UIColor clearColor];
    [self.tableView setBackgroundView:backgroundView];
}


-(UILabel *) RECAPLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, self.tableView.rowHeight)];
    label.text = [NSString stringWithFormat:@"R"];
    label.font = [UIFont fontWithName:kContrastFont size:14];
    label.textColor = kActiveColor;
    [label sizeToFit];
    return label;
}

-(UIImageView *) folderImage
{
    
    UIImage *image = [kFolderImage imageWithColor:kActiveColor];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    return imageView;
}

@end


//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTBookmarkViewController.h"
#import "DkTDocketViewController.h"
#import "MBProgressHUD.h"
#import "PACERClient.h"
#import "DkTDocket.h"
#import "UIImage+Utilities.h"
#import "FSButton.h"
#import "UIResponder+FirstResponder.h"
#import <QuartzCore/QuartzCore.h>
#import "DkTSession.h"
#import "DkTCodeManager.h"
#import "DkTUser.h"
#import "DkTAlertView.h"
#import "DkTSettings.h"
#import "DkTDetailViewController.h"
#import "ReaderViewController.h"
#import "ZSRoundCell.h"
#import "UIViewController+PKRevealController.h"
#import "PKRevealController.h"

@interface DkTBookmarkViewController ()

@property (nonatomic, strong) NSMutableArray *updating;

@end

@implementation DkTBookmarkViewController {
}

- (id)init
{
    if(self = [super init])
    {
        [self initialize];
    }
    return self;
}

-(void) initialize {
    self.bookmarkManager = [DkTBookmarkManager sharedManager];
    [self.bookmarkManager setDelegate:self];
    self.bookmarks = [[self.bookmarkManager bookmarks] mutableCopy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor activeColor];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    _tableView = nil;
}

-(void) setup
{
    self.updating = [[NSMutableArray alloc] initWithCapacity:self.bookmarks.count];
    
    for(int i = 0; i < self.bookmarks.count; i++) [self.updating addObject:@(0)];
    
    [self.view addSubview:self.noDocumentLabel];
    self.noDocumentLabel.hidden = self.bookmarks.count > 0;
    [self.view addSubview:self.tableView];
    
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
        
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            
            [alertView dismissAnimated:YES];
            
            [self.parentViewController.revealController showViewController:self.parentViewController.revealController.leftViewController animated:YES completion:^(BOOL finished) {
                
            }];
            
        }];
        
        
        [alertView show];
        
        return FALSE;
    }
    
    return TRUE;
    
}


-(void) lookupDocket:(NSInteger)row
{
    
    if([self connectivityStatus])
    {
        DkTDocket *selectedDocket = [self.bookmarks objectAtIndex:row];
        ZSRoundCell *cell = [self cellForDocket:selectedDocket];
        
        if(cell.badgeString.length > 0)
        {
            cell.badgeString = @"\u2713";
        }
        
        if(selectedDocket.link.length > 0)
        {
            UIResponder *firstResponder = [UIResponder currentFirstResponder];
            [firstResponder resignFirstResponder];
            
            
            
            [[PACERClient sharedClient] retrieveDocket:selectedDocket sender:self];
        }
    }
    
}

-(void) showSavedDocket:(DkTDocket *)docket
{
    NSArray *entries = [[DkTBookmarkManager sharedManager] savedDocket:docket];
    
    ZSRoundCell *cell = [self cellForDocket:docket];
    
    if(cell.badgeString.length > 0)
    {
        cell.badgeString = @"\u2713";
    }
    
    if(entries.count > 0)
    {
        [self handleSavedDocket:docket entries:entries];
    }
}

-(void) updateDocket:(DkTDocket *)docket
{
    if([self connectivityStatus])
    {
        PACERClient *client = [PACERClient sharedClient];
        [client retrieveDocket:docket sender:self to:[client pacerDateString:[NSDate date]] from:docket.updated];
        [self.updating replaceObjectAtIndex:[self.bookmarks indexOfObject:docket] withObject:@1];
        ZSRoundCell *cell = [self cellForDocket:docket];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        spinner.frame = CGRectMake(0, 0, 24, 24);
        cell.accessoryView = spinner;
        [spinner startAnimating];
    }
}

-(void) deleteBookmarkAtIndex:(NSInteger)index
{
    
    DkTDocket *item = [self.bookmarks objectAtIndex:index];
    [self.bookmarks removeObjectAtIndex:index];
    [self.bookmarkManager deleteBookmark:item];
    [self resizeTableViewForHeight];
    
    if(self.bookmarks.count > 0) [self.tableView reloadData];
    
    else self.noDocumentLabel.hidden = FALSE;
    
}

-(void) loadBookmarks {
    _bookmarks = nil;
    _bookmarks = [NSMutableArray arrayWithArray:[self.bookmarkManager bookmarks]];
    [self.tableView reloadData];
}

-(void) reload {
    [self loadBookmarks];
    self.noDocumentLabel.hidden = (self.bookmarks.count > 0);
}

-(void) resizeTableViewForHeight {
    NSInteger maxRows = PAD_OR_POD(10, 7);
    CGRect frame; frame.size.height = _tableView.rowHeight * MIN(self.bookmarks.count, maxRows); frame.size.width = self.view.frame.size.width*.85; frame.origin = CGPointMake((self.view.frame.size.width -frame.size.width)/2.0,(self.view.frame.size.width -frame.size.width)/2.0); _tableView.frame = frame;
}

-(void) updateAllBookmarks
{
    if([self connectivityStatus])
    {
        DkTAlertView *alert = [[DkTAlertView alloc] initWithTitle:@"Update All" andMessage:@"Update all bookmarked dockets?"];
        [alert addButtonWithTitle:@"YES" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            
            NSArray *bookmarks = [NSArray arrayWithArray:self.bookmarks];
            [[DkTBookmarkManager sharedManager] updateBookmarks:bookmarks];
            [alertView dismissAnimated:YES];
            
            for(ZSRoundCell *cell in [self.tableView visibleCells])
            {
                UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                
                spinner.frame = CGRectMake(0, 0, 24, 24);
                cell.accessoryView = spinner;
                [spinner startAnimating];
                
            }
            
            for(int i = 0; i < self.updating.count; ++i)
            {
                [self.updating replaceObjectAtIndex:i withObject:@1];
            }
        }];
        [alert addButtonWithTitle:@"NO" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            [alertView dismissAnimated:YES];
        }];
        
        [alert show];
    }
}


-(void) menuForIndexPath:(NSIndexPath *)indexPath {
    
    DkTDocket *docket = [self.bookmarks objectAtIndex:indexPath.row];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    [self.tableView becomeFirstResponder];
    
    __weak DkTBookmarkViewController *weakSelf = self;
    
    
    PSMenuItem *saved = [[PSMenuItem alloc] initWithTitle:@"" block:^{
        [weakSelf showSavedDocket:docket];
        
    }];
    
    PSMenuItem *update = [[PSMenuItem alloc] initWithTitle:@"" block:^{
        [weakSelf updateDocket:docket];
        
    }];
    
    [saved cxa_setImage:[[UIImage imageNamed:@"save"] imageWithColor:[UIColor inactiveColor]] forTitle:@" "];
    
    [update cxa_setImage:[kUpdateImage imageWithColor:[UIColor inactiveColor]] forTitle:@"  "];
    
    
    [menu setMenuItems:@[saved, update]];
    
    //CGFloat width =  self.detailViewController.contentSizeForViewInPopover.width;
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    //rect.size.width = width;
    
    [menu setTargetRect:rect inView:self.tableView];
    [menu setMenuVisible:YES];
}


-(void) addBadgeToDocket:(DkTDocket *)docket number:(int)number
{
    NSInteger index = [self.bookmarks indexOfObject:docket];
    ZSRoundCell *cell = [self cellForDocket:docket];
    cell.accessoryView = nil;
    [self.updating replaceObjectAtIndex:index withObject:@0];
    cell.badgeString = (number != 0) ? [NSString stringWithFormat:@"%d", number] : @"\u2713";
    
    NSString *subtitle = [NSString stringWithFormat:@"%@, %@", docket.case_num, [DkTCodeManager translateCode:[docket court]  inputFormat:DkTCodePACERDisplayKey outputFormat:DkTCodeBluebookKey]];
    
    if(docket.updated.length > 0)
    {
        NSString *datestring = [NSString stringWithFormat:PAD_OR_POD(@"  (last checked %@)", @"\n(last checked %@)") , docket.updated];
        subtitle = [subtitle stringByAppendingString:datestring];
    }
    
    cell.detailTextLabel.text = subtitle;
    [cell.detailTextLabel setNeedsDisplay];
}

-(ZSRoundCell *) cellForDocket:(DkTDocket *)docket
{
    NSInteger index = [self.bookmarks indexOfObject:docket];
    return (ZSRoundCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [[UIMenuController sharedMenuController] update];
    
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    
    for(int i = 0; i < rows; ++i)
    {
        ZSRoundCell *cell = (ZSRoundCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        cell.badgeString = nil;
    }
}

#pragma mark - UI

-(UILabel *) noDocumentLabel {
    
    if(_noDocumentLabel == nil) {
        _noDocumentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.center.y-30, self.view.frame.size.width, 24)];
        _noDocumentLabel.text = @"You have no bookmarks.";
        _noDocumentLabel.textColor = [UIColor inactiveColor];
        _noDocumentLabel.backgroundColor = [UIColor clearColor];
        _noDocumentLabel.font = [UIFont fontWithName:kMainFont size:PAD_OR_POD(16, 12)];
        _noDocumentLabel.textAlignment = NSTextAlignmentCenter;
        _noDocumentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    }
    
    return _noDocumentLabel;
    
}
-(UITableView *) tableView
{
    if(_tableView == nil)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        
        _tableView.rowHeight = PAD_OR_POD(65, 60);
        [self resizeTableViewForHeight];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.scrollEnabled = YES;
        _tableView.bounces = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor clearColor];
        [_tableView setBackgroundView:backgroundView];
        IOS7(_tableView.separatorInset = UIEdgeInsetsZero;, );
        _tableView.layer.cornerRadius = 5.0;
        
    }
    
    return _tableView;
}



#pragma mark - TableView Delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.bookmarks.count; }

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZSRoundCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    
    CGFloat unit = self.tableView.rowHeight*.9;
    
    //switch the style
    if(cell == nil)
    {
        cell = [[ZSRoundCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont fontWithName:kLightFont size:PAD_OR_POD(14, 13)];
        cell.textLabel.adjustsFontSizeToFitWidth = NO;
        cell.textLabel.numberOfLines = 1;
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor darkerTextColor];
        cell.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        cell.detailTextLabel.font = [UIFont fontWithName:kContrastFont size:9];
        cell.detailTextLabel.textColor = [UIColor darkerTextColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.numberOfLines = 2;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor inactiveColor];
        cell.accessoryView.backgroundColor = [UIColor clearColor];
        cell.badgeTextColor = [UIColor inactiveColor];
        cell.badgeColor = [UIColor activeColor];
        cell.badgeRightOffset = PAD_OR_POD(unit*3+5, 5);
        cell.contentView.helpText = @"Select the disk to load saved docket as last checked. Select the calendar to update a docket.  Press and hold the bookmarks tab below to update all dockets.";
            
        [cell addGestureRecognizer:self.longPress];
    }
    

    if(indexPath.row == 0)
    {
        cell.cornerRadius = 5.0f;
        cell.cornerRounding = UIRectCornerTopLeft | UIRectCornerTopRight;
    }
    
    else if(indexPath.row == self.bookmarks.count)
    {
        cell.cornerRadius = 5.0f;
        cell.cornerRounding = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    }
    
    else {
        cell.cornerRadius = 0;
    }
    
    cell.imageView.image = [[DkTImageCache sharedCache] imageNamed:@"bookmark" color:[UIColor activeColor]];
    cell.imageView.transform = CGAffineTransformMakeScale(.5, .5);
    cell.contentView.backgroundColor = (indexPath.row%2 == 0) ? [UIColor inactiveColor] : [UIColor inactiveColorDark];
    cell.backgroundView = [[UIView alloc] init];
    cell.backgroundView.backgroundColor = cell.contentView.backgroundColor;
    
    __weak DkTBookmarkViewController *weakSelf = self;
    
    DkTDocket *item = [self.bookmarks objectAtIndex:indexPath.row];
    
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            /*FSButton *docketButton = [FSButton buttonWithIcon:kDocketImage colors:@[cell.contentView.backgroundColor, [UIColor activeColor]] title:@"" actionBlock:^{
                
                
                if([weakSelf connectivityStatus]) [weakSelf lookupDocket:indexPath.row];
                
                
            }];
            docketButton.helpText = @"Reload and show PACER Docket. PACER Login Required.";
            docketButton.frame = CGRectMake(cell.contentView.frame.size.width - unit*3,self.tableView.rowHeight/2. - unit/2., unit,unit);
            docketButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            */
            FSButton *savedDocket = [FSButton buttonWithIcon:[UIImage imageNamed:@"save"] colors:@[cell.contentView.backgroundColor, [UIColor activeColor]] title:@"" actionBlock:^{
                
                [weakSelf showSavedDocket:item];
            }];
            savedDocket.helpText = @"Load the saved docket.";
            savedDocket.frame = CGRectMake(cell.contentView.frame.size.width - unit*2, self.tableView.rowHeight/2. - unit/2., unit, unit);
            savedDocket.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            
            FSButton *updateDocket = [FSButton buttonWithIcon:kUpdateImage colors:@[cell.contentView.backgroundColor, [UIColor activeColor]] title:@"" actionBlock:^{
                
                [weakSelf updateDocket:item];
                
            }];
            
            updateDocket.helpText = @"Update the saved docket.  Press and hold the bookmarks tab to update all saved dockets.";
            updateDocket.frame = CGRectMake(cell.contentView.frame.size.width - unit, self.tableView.rowHeight/2. - unit/2., unit, unit);
            updateDocket.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            
            CGFloat width = CGRectGetMinX(savedDocket.frame);
            cell.textLabel.frame =  CGRectMake(cell.textLabel.frame.origin.x,cell.textLabel.frame.origin.y,width,cell.textLabel.frame.size.height);
            
            //[cell.contentView addSubview:docketButton];
            [cell.contentView addSubview:savedDocket];
            [cell.contentView addSubview:updateDocket];
        }
    
        else
        {
            [PSMenuItem installMenuHandlerForObject:self.tableView];
        }
    
        cell.textLabel.text = item.name;
        NSString *subtitle = [NSString stringWithFormat:@"%@, %@", item.case_num, [DkTCodeManager translateCode:[item court]  inputFormat:DkTCodePACERDisplayKey outputFormat:DkTCodeBluebookKey]];
    
    if(item.updated.length > 0)
    {
        NSString *datestring = [NSString stringWithFormat:PAD_OR_POD(@"  (last checked %@)", @"\n(last checked %@)") , item.updated];
        subtitle = [subtitle stringByAppendingString:datestring];
    }
        cell.detailTextLabel.text = subtitle;
    
    if([[self.updating objectAtIndex:indexPath.row] boolValue])
    {
        if(cell.accessoryView == nil)
        {
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            
            spinner.frame = CGRectMake(0, 0, 24, 24);
            cell.accessoryView = spinner;
            [spinner startAnimating];
        }
    }
    
    else
    {
        cell.accessoryView = nil;
    }
    return cell;
}
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) [self menuForIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {  return NO; }

-(BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {return YES; }

-(void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    DkTDocket *item = [self.bookmarks objectAtIndex:sourceIndexPath.row];
    [self.bookmarkManager moveBookmark:item toIndex:destinationIndexPath.row];
    _bookmarks = [[self.bookmarkManager bookmarks] mutableCopy];
    [self.tableView reloadData];
    //do stuff
     
}
-(void) scrollViewWillBeginDragging:(UIScrollView *)scrollView { [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES]; }


#pragma mark PACERClientProtocol
-(void) handleDocketError:(DkTDocket *)docket
{
    NSInteger index = [self.bookmarks indexOfObject:docket];
    ZSRoundCell *cell = [self cellForDocket:docket];
    cell.accessoryView = nil;
    [self.updating replaceObjectAtIndex:index withObject:@0];
}
-(void) handleDocket:(DkTDocket *)docket entries:(NSArray *)entries to:(NSString *)to from:(NSString *)from
{
    if(from.length > 0)
    {
        NSInteger n = [[DkTBookmarkManager sharedManager] appendEntries:entries toSavedDocket:docket];
        [self addBadgeToDocket:docket number:(int)n];
    }
    
    else
    {

        DkTDocketViewController *nextViewController = [[DkTDocketViewController alloc] initWithDocket:docket];
        nextViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        nextViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        UIViewController *parent = [self parentViewController];
        
        nextViewController.masterViewController.docketEntries = entries;
        [nextViewController.masterViewController.tableView reloadData];
        [parent presentViewController:nextViewController animated:YES completion:^{
            
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
            [[DkTBookmarkManager sharedManager] bookmarkDocket:docket withDocketEntries:entries];
        }];
    }
    
}

-(void) handleSavedDocket:(DkTDocket *)docket entries:(NSArray *)entries
{
    DkTDocketViewController *nextViewController = [[DkTDocketViewController alloc] initWithDocket:docket];
    nextViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    nextViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    UIViewController *parent = [self parentViewController];
    
    nextViewController.masterViewController.docketEntries = [NSArray arrayWithArray:entries];
    entries = nil;
    nextViewController.masterViewController.local = YES;
    [nextViewController.masterViewController.tableView reloadData];
    
    [parent presentViewController:nextViewController animated:YES completion:^{
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }];
}
     
-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
        
    if(editingStyle == UITableViewCellEditingStyleDelete) { [self deleteBookmarkAtIndex:indexPath.row]; }
    
}

#pragma mark Bookmark Delegate Methods
-(void) didAddBookmark:(DkTDocket *)bookmarkedItem
{
    [self.bookmarks insertObject:bookmarkedItem atIndex:0];
    [self.updating insertObject:@0 atIndex:0];
    [self resizeTableViewForHeight];
    if(self.bookmarks.count > 0) self.noDocumentLabel.hidden = YES;
    [self.tableView reloadData];
}

#pragma mark - Gesture Recognizer
-(UILongPressGestureRecognizer *) longPress {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.delegate = self;
    return longPress;
}

-(void) handleLongPress:(UILongPressGestureRecognizer *)sender {
    if(sender.state == UIGestureRecognizerStateBegan)
        [self.tableView setEditing:!self.tableView.editing];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end

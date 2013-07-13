//
//  RECAPBookmarkViewController.m
//  RECAPp
//
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

@interface DkTBookmarkViewController ()

@end

@implementation DkTBookmarkViewController

- (id)init
{
    if(self = [super init])
    {
        self.bookmarkManager = [DkTBookmarkManager sharedManager];
        [self.bookmarkManager setDelegate:self];
        _bookmarks = [[self.bookmarkManager bookmarks] mutableCopy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    
    self.view.backgroundColor = kActiveColor;
    [self setup];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return MAX(1, self.bookmarks.count);
}

-(void) setup
{
    [self.view addSubview:self.tableView];
}
#pragma mark
-(void) didAddBookmark:(DkTDocket *)bookmarkedItem
{
    [self.bookmarks insertObject:bookmarkedItem atIndex:0];
    [self.tableView reloadData];
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DkTBookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    
    
    //switch the style
    if(cell == nil)
    {
        cell = [[DkTBookmarkCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont fontWithName:kLightFont size:16];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = kDarkTextColor;
        cell.detailTextLabel.font = [UIFont fontWithName:kContrastFont size:12];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.contentView.backgroundColor = (indexPath.row%2 == 0) ? kInactiveColor : kInactiveColorDark;
    cell.backgroundView = [[UIView alloc] init];
    cell.backgroundView.backgroundColor = (indexPath.row%2 == 0) ? kInactiveColor : kInactiveColorDark;
    cell.accessoryView.backgroundColor = [UIColor clearColor];
    
    if(self.bookmarks.count > 0)
    {
        DkTDocket *item = [self.bookmarks objectAtIndex:indexPath.row];
        cell.textLabel.text = item.name;
        cell.imageView.image = [kBookmarkImage imageWithColor:kActiveColor];
        cell.imageView.transform = CGAffineTransformMakeScale(.5, .5);
        cell.detailTextLabel.text = item.court;
        
        FSButton *docketButton = [FSButton buttonWithIcon:kDocketImage colors:@[[UIColor clearColor], kActiveColor] title:@"" actionBlock:^{
           
            [self showDocket:indexPath.row];
        }];
        
        CGFloat unit = self.tableView.rowHeight*3/2.;
        
        docketButton.helpText = @"Reload and show PACER Docket. PACER Login Required.";
        docketButton.frame = CGRectMake(cell.contentView.frame.size.width - unit*2,self.tableView.rowHeight/2. - unit/2., unit,unit);
        docketButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                
        FSButton *savedDocket = [FSButton buttonWithIcon:kUpdateImage colors:@[[UIColor clearColor], kActiveColor] title:@"" actionBlock:^{
            
           // [self showSavedDocket:indexPath.row];
        }];
        savedDocket.helpText = @"Check for docket updates since last visit.";
        savedDocket.frame = CGRectMake(cell.contentView.frame.size.width - unit, self.tableView.rowHeight/2. - unit/2., unit, unit);
        savedDocket.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        
        [cell.contentView addSubview:docketButton];
        [cell.contentView addSubview:savedDocket];
    }
    else
    {
        cell.textLabel.text = @"You currently have no bookmarked dockets.";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = kActiveColor;
        
    }
    
    cell.contentView.backgroundColor = (indexPath.row%2 == 0) ? kInactiveColor : kInactiveColorDark;
    
    
    
    return cell;
}


-(void) showDocket:(NSInteger)row
{
    if([DkTSession currentSession])
    {
        DkTDocket *selectedDocket = [self.bookmarks objectAtIndex:row];
        
        if(selectedDocket.link.length > 0)
        {
            UIResponder *firstResponder = [UIResponder currentFirstResponder];
            [firstResponder resignFirstResponder];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.color = kActiveColor;
            
            [[PACERClient sharedClient] getDocket:selectedDocket sender:self];
        }
    }
}

-(void) handleDocket:(DkTDocket *)docket entries:(NSArray *)entries
{
    DkTDocketViewController *nextViewController = [[DkTDocketViewController alloc] initWithDocket:docket];
    nextViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    nextViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    UIViewController *parent = [self parentViewController];
    
    nextViewController.masterViewController.docketEntries = entries;
    [nextViewController.masterViewController.tableView reloadData];
    [parent presentViewController:nextViewController animated:YES completion:^{
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
    
}


-(void) loadBookmarks
{
    _bookmarks = [NSMutableArray arrayWithArray:[self.bookmarkManager bookmarks]];
    [self.tableView reloadData];
}

-(void) reload
{
    [self loadBookmarks];
}

-(void) writeBookmarks
{
    [self.bookmarkManager writeItems:self.bookmarks];
}

-(void) moveBookmarkAtIndex:(NSInteger)originalIndex toNewIndex:(NSInteger)newIndex
{
    DkTDocket *item = [self.bookmarks objectAtIndex:originalIndex];
    
    [self.bookmarks removeObjectAtIndex:originalIndex];
    [self.bookmarks insertObject:item atIndex:newIndex];
    [self writeBookmarks];
    [self.tableView reloadData];
    
}

-(void) deleteBookmarkAtIndex:(NSInteger)index
{
    DkTDocket *item = [self.bookmarks objectAtIndex:index];
    
    [self.bookmarks removeObjectAtIndex:index];
    [self.bookmarkManager deleteBookmark:item.link];
    
}

-(BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        
        [self deleteBookmarkAtIndex:indexPath.row];
    }

}

-(void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [self moveBookmarkAtIndex:sourceIndexPath.row toNewIndex:destinationIndexPath.row];
}

-(UITableView *) tableView
{
    if(_tableView == nil)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        
        _tableView.rowHeight = 60;
        
        CGRect frame;
        frame.size.height = _tableView.rowHeight * MAX(self.bookmarks.count, 1);
        frame.size.width = self.view.frame.size.width*.85;
        frame.origin = CGPointMake((self.view.frame.size.width -frame.size.width)/2.0,(self.view.frame.size.width -frame.size.width)/2.0);
        _tableView.frame = frame;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.scrollEnabled = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor clearColor];
        [_tableView setBackgroundView:backgroundView];
        
        _tableView.layer.cornerRadius = 5.0;
    }
    
    return _tableView;
}


@end

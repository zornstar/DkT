//
//  RECAPMultiDocSelectionViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 6/13/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTMultiDocSelectionViewController.h"
#import "DkTLoginViewController.h"
#import "DkTSearchViewController.h"
#import "DkTUser.h"
#import "DkTDocketEntry.h"
#import "FSButton.h"
#import "MBProgressHUD.h"
#import "UIImage+Utilities.h"

#import "DkTDocketTableViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface DkTMultiDocSelectionViewController ()
{
    CGSize _size;
}
@end


@implementation DkTMultiDocSelectionViewController

- (id)initWithSize:(CGSize)size
{
    self = [super init];
    if (self) {
        _size = size;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.view.backgroundColor = kInactiveColorDark;
    CGRect frame = self.view.frame;
    frame.size = _size;
    self.view.frame = frame;
    
    [self.view addSubview:self.tableView];
    
    
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


+(void) presentAsPopover:(UIViewController *)viewController size:(CGSize)size choices:(NSArray *)choices
{
    DkTMultiDocSelectionViewController *popover = [[DkTMultiDocSelectionViewController alloc] initWithSize:size];
    
    popover.docketEntries = choices;
    
    popover.view.layer.cornerRadius = 5.0;
    
    
    for(UIView *subview in viewController.view.subviews)
    {
        
        subview.userInteractionEnabled = NO;
        subview.alpha = .3;
    }
    
    [viewController addChildViewController:popover];
    [viewController.view addSubview:popover.view];
    popover.view.center = CGPointMake(viewController.view.center.x, viewController.view.center.y*.66);
}

-(UITableView *) tableView
{
    if(_tableView == nil)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        
        _tableView.rowHeight = 60;
        
        CGRect frame;
        frame.size = _size;
        frame.origin = CGPointZero;
        _tableView.frame = frame;
        _tableView.center = self.parentViewController.view.center;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.scrollEnabled = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor clearColor];
        [_tableView setBackgroundView:backgroundView];
    }
    
    return _tableView;
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
  
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    
}

#pragma mark - PACER/RECAP Protocol

-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path
{
    //handle a downloaded document
    
    DkTDocketTableViewController *parentViewController = (DkTDocketTableViewController *)[self parentViewController];
    
    [parentViewController didDownloadDocketEntry:entry atPath:path];
    
}

-(void) handleMultidocRequest:(DkTDocketEntry *)entry entries:(NSArray *)entries
{
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    
    DkTDocketTableViewController *parentViewController = (DkTDocketTableViewController *)[self parentViewController];
    
    [parentViewController handleMultidocRequest:entry entries:entries];
}

-(void) handleDocLink:(DkTDocketEntry *)entry docLink:(NSString *)docLink
{
    DkTDocketTableViewController *parentViewController = (DkTDocketTableViewController *)[self parentViewController];
    
    [parentViewController handleDocLink:entry docLink:docLink];
    
    //[RECAPClient uploadDocMeta:entry];
}

-(void) handleDocumentsFromEntry:(DkTDocketEntry *)entry entries:(DkTDocketEntry *)entries
{
    
    
}



@end

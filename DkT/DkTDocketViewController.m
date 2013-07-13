//
//  RECAPDocketViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDocketViewController.h"
#import "MBProgressHUD.h"
#import "DkTDocket.h"
#import "PACERClient.h"

@interface DkTDocketViewController ()
{
}
@end

@implementation DkTDocketViewController

- (id)initWithDocket:(DkTDocket *)dkt
{
    self = [super init];
    if (self) {
        _docket = dkt;
        
        self.splitViewController = [[UISplitViewController alloc] init];
        self.masterViewController = [[DkTDocketTableViewController alloc] init];
        self.detailViewController = [[DkTDetailViewController alloc] init];
        
        UINavigationController *nav1 = [[UINavigationController alloc] initWithRootViewController:self.masterViewController];
        UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:self.detailViewController];
        
        self.detailViewController.title = dkt.name;
        self.detailViewController.docket = dkt;
        
        self.masterViewController.title = @"Docket";
        self.masterViewController.docket = dkt;
        
        self.splitViewController.viewControllers = @[nav1, nav2];
        self.splitViewController.delegate = self.detailViewController;
        self.masterViewController.detailViewController = self.detailViewController;
        
        [self addChildViewController:self.splitViewController];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.splitViewController.view.bounds = self.view.bounds;
    [self.view addSubview:self.splitViewController.view];
}

-(void) viewWillAppear:(BOOL)animated
{
    [self.masterViewController.view setNeedsLayout];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL) canBecomeFirstResponder
{
    return YES;
}
@end

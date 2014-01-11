
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//


#import "DkTDetailViewController.h"
#import "DkTDocketViewController.h"
#import "MBProgressHUD.h"
#import "DkTDocket.h"
#import "DkTSpecificDocumentViewController.h"
#import "PACERClient.h"
#import "PKRevealController.h"

@interface DkTDocketViewController ()

@property (nonatomic, strong) UIViewController *baseViewController;

@end

@implementation DkTDocketViewController

- (id)initWithDocket:(DkTDocket *)dkt
{
    self = [super init];
    if (self) {
        _docket = dkt;
        
        
        self.masterViewController = [[DkTDocketTableViewController alloc] init];
        self.detailViewController = [[DkTDetailViewController alloc] init];
        
        self.baseViewController = PAD_OR_POD([self setupPad], [self setupPod]);
        
        
        
        
        [self commonSetup];
        
        [self addChildViewController:self.baseViewController];
        
        
    }
    return self;
}


-(UISplitViewController *) setupPad
{
    self.splitViewController = [[UISplitViewController alloc] init];
    UINavigationController *nav1 = [[UINavigationController alloc] initWithRootViewController:self.masterViewController];
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:self.detailViewController];
    
    
    self.splitViewController.viewControllers = @[nav1, nav2];
    
    self.splitViewController.delegate = self.detailViewController;
    nav1.view.clipsToBounds = NO;
    
    return self.splitViewController;
}

-(PKRevealController *) setupPod
{
    UINavigationController *nav1 = [[UINavigationController alloc] initWithRootViewController:self.masterViewController];
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:self.detailViewController];
    nav1.view.clipsToBounds = NO;
    
    PKRevealController *revealController = [[PKRevealController alloc] initWithFrontViewController:nav2 leftViewController:nav1 options:@{PKRevealControllerAllowsOverdrawKey:@TRUE}];
    return revealController;
}

-(void) commonSetup
{
    DkTSpecificDocumentViewController *noDocVC = [[DkTSpecificDocumentViewController alloc] initWithType:DkTNoDocumentViewControllerType];
    [self.detailViewController addChildViewController:noDocVC];
    [self.detailViewController.view addSubview:noDocVC.view];
    self.detailViewController.title = self.docket.name;
    self.detailViewController.docket = self.docket;
    self.detailViewController.filePath = nil;
    
   
    self.masterViewController.docket = _docket;
    
    self.masterViewController.detailViewController = self.detailViewController;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.baseViewController.view.bounds = self.view.bounds;
    
    [self.view addSubview:self.baseViewController.view];
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

-(void) dealloc
{
    _detailViewController = nil;
    _masterViewController = nil;
    _splitViewController = nil;
    _baseViewController = nil;
    _docket = nil;
}


-(BOOL) canBecomeFirstResponder
{
    return YES;
}
@end

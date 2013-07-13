//
//  RECAPSidePanelController.m
//  RECAPp
//
//  Created by Matthew Zorn on 6/24/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSidePanelController.h"
#import "DkTSettingsViewController.h"
#import "DkTLoginViewController.h"
#import "UIViewController+PKRevealController.h"
#import "PKRevealController.h"

@interface DkTSidePanelController ()

@end

@implementation DkTSidePanelController

#define kHeightMargin 1/10.

- (id)init
{
    self = [super init];
    if (self) {
        
        self.settingsViewController = [[DkTSettingsViewController alloc] init];
        self.loginViewController = [[DkTLoginViewController alloc] init];
        
        
        [self addChildViewController:self.settingsViewController];
        [self addChildViewController:self.loginViewController];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat width = self.revealController.leftViewWidthRange.location;
    
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(.025*width,.05*self.view.frame.size.height, width*.95, .9*self.view.frame.size.height)];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    CGFloat heightUnit = self.containerView.frame.size.height*kHeightMargin;
    CGRect loginFrame = CGRectMake(0,heightUnit,self.containerView.frame.size.width,heightUnit*3);
    CGRect settingsFrame = CGRectMake(0,CGRectGetMaxY(loginFrame)+2*heightUnit,self.containerView.frame.size.width, heightUnit*3);
    
    self.settingsViewController.view.frame = settingsFrame;
    self.loginViewController.view.frame = loginFrame;
    self.settingsViewController.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.loginViewController.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    
    [self.containerView addSubview:self.loginViewController.view];
    [self.containerView addSubview:self.settingsViewController.view];
    
    self.containerView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = kInactiveColorDark;
    
    [self.view addSubview:self.containerView];
	
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) resignWithCompletion:(PKDefaultCompletionHandler)completion
{
    [self.revealController resignPresentationModeEntirely:YES animated:YES completion:completion];
}
@end

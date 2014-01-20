//  Created by Matthew Zorn on 6/24/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSidePanelController.h"
#import "DkTSettingsViewController.h"
#import "DkTLoginViewController.h"
#import "UIViewController+PKRevealController.h"
#import "UIImage+Utilities.h"

@interface DkTSidePanelController ()

@end

@implementation DkTSidePanelController

#define kHeightMargin 1/16.

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
    
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(.025*width,.03*self.view.frame.size.height, width*.95, .99*self.view.frame.size.height)];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    CGRect loginFrame;
    CGRect settingsFrame;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        CGFloat heightUnit = self.containerView.frame.size.height*kHeightMargin;
        loginFrame = CGRectMake(0,heightUnit,self.containerView.frame.size.width,heightUnit*4);
        settingsFrame = CGRectMake(0,CGRectGetMaxY(loginFrame)+4*heightUnit,self.containerView.frame.size.width, heightUnit*4.5);
    }
    
    else
    {
        CGFloat height = self.containerView.frame.size.height;
        loginFrame = CGRectMake(self.containerView.frame.size.width*.05,height*.03,self.containerView.frame.size.width*.9,height*.5);
        settingsFrame = CGRectMake(0,height*.575,self.containerView.frame.size.width, height*.4);
    }
    
    
    self.settingsViewController.view.frame = settingsFrame;
    self.loginViewController.view.frame = loginFrame;
    self.settingsViewController.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.loginViewController.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    
    [self.containerView addSubview:self.loginViewController.view];
    [self.containerView addSubview:self.settingsViewController.view];
    
    self.containerView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor inactiveColorDark];
    
    [self.view addSubview:self.containerView];

    /* draw Logo
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        imageView.frame = CGRectMake(self.containerView.center.x-65,self.view.frame.size.height-80, 60, 60);
        c.font = [UIFont fontWithName:kMainFont size:16];
        c.frame = CGRectMake(CGRectGetMaxX(imageView.frame),imageView.center.y-5, 60, 18);
    }
    
    else
    {
        CGFloat x = self.containerView.center.x-45;
        imageView.frame = CGRectMake(x,self.view.frame.size.height-45, 45, 45);
        c.frame = CGRectMake(CGRectGetMaxX(imageView.frame),imageView.center.y-4, 60, 15);
        c.font = [UIFont fontWithName:kMainFont size:12];
    }
    
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
    [self.view addSubview:c];
    [self.view sendSubviewToBack:c];
    */
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) resignWithCompletion:(PKDefaultCompletionHandler)completion
{
    [self.revealController showViewController:self.revealController.frontViewController animated:YES completion:completion];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.loginViewController.view endEditing:YES];
}
@end

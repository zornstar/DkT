
//
//  Created by Matthew Zorn on 5/26/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTRootViewController.h"
#import "DkTSidePanelController.h"
#import "DkTTabViewController.h"
#import "DkTPodTabBarController.h"
#import "FSPanelTab.h"

@interface DkTRootViewController ()

@property (nonatomic, strong) FSPanelTab *tab;

@end

@implementation DkTRootViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        self.leftViewController = [[DkTSidePanelController alloc] init];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) self.frontViewController = [[DkTTabViewController alloc] init];
        
        else self.frontViewController = [[DkTPodTabBarController alloc] init];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _tab = [[FSPanelTab alloc] initWithIcon:kTabImage colors:@[[UIColor inactiveColorDark], [UIColor inactiveColor]]];
    _tab.helpText = @"Touch or pull tab to reveal the control panel.";
    CGRect fvFrame = self.frontViewController.view.frame;
    _tab.frame = CGRectMake(0, fvFrame.size.height*.8, PAD_OR_POD(60, 45), PAD_OR_POD(40, 30));
    [_tab addTarget:self action:@selector(performSlide:) forControlEvents:UIControlEventTouchUpInside];
    [self.frontViewController.view addSubview:_tab];
    
    _tab.layer.shadowColor = [[UIColor blackColor] CGColor];
    _tab.layer.shadowOpacity = .33;
    _tab.layer.shadowOffset = CGSizeMake(1,1);
    _tab.layer.shadowRadius = 1;
    _tab.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL) shouldAutorotate
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

-(void) viewWillAppear:(BOOL)animated
{
    
}
-(void) performSlide:(id)sender
{
    if(self.focusedController == self.frontViewController)
    {
        [self showViewController:self.leftViewController];
    }
    
    else
    {
        [self resignPresentationModeEntirely:YES animated:YES completion:^(BOOL finished) {
            
        }];
    }
}

@end

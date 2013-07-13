//
//  RECAPRootViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/26/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTRootViewController.h"
#import "DkTSidePanelController.h"
#import "DkTTabViewController.h"
#import "DkTConstants.h"
#import "FSPanelTab.h"

@interface DkTRootViewController ()
{
    FSPanelTab *_tab;
}
@end

@implementation DkTRootViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        self.leftViewController = [[DkTSidePanelController alloc] init];
        self.frontViewController = [[DkTTabViewController alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    _tab = [[FSPanelTab alloc] initWithIcon:kTabImage colors:@[kInactiveColorDark, kInactiveColor]];
    CGRect fvFrame = self.frontViewController.view.frame;
    _tab.frame = CGRectMake(0, fvFrame.size.height*.66, 60, 40);
    [_tab addTarget:self action:@selector(performSlide:) forControlEvents:UIControlEventTouchUpInside];
    [self.frontViewController.view addSubview:_tab];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL) shouldAutorotate
{
    return YES;
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

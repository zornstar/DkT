//
//  SegmentedController.m
//  DkT
//
//  Created by Matthew Zorn on 3/23/14.
//  Copyright (c) 2014 Matthew Zorn. All rights reserved.
//

#import "DkTSegmentedController.h"
#import "DkTSearchViewController.h"
#import "DkTRecentDocketViewController.h"
#import "HMSegmentedControl.h"

@interface DkTSegmentedController ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, retain) UIViewController * currentViewController;
@property (nonatomic, strong) HMSegmentedControl *segmentedControl;
@property (nonatomic, strong) UINavigationController *searchNavController;

@end

@implementation DkTSegmentedController

- (void)viewDidLoad {
    [super viewDidLoad];
    // add viewController so you can switch them later.
    UIViewController *vc = [self viewControllerForSegmentIndex:0];
    [self addChildViewController:vc];
    self.contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.view.backgroundColor = [UIColor activeColor];
    [self.view addSubview:self.contentView];
    vc.view.frame = self.contentView.bounds;
    [self.contentView addSubview:vc.view];
    [self.contentView addSubview:self.segmentedControl];
    self.currentViewController = vc;
}
- (void)segmentChanged:(UISegmentedControl *)sender {
    [self.segmentedControl removeFromSuperview];
    UIViewController *vc = [self viewControllerForSegmentIndex:sender.selectedSegmentIndex];
    [self addChildViewController:vc];
    [self transitionFromViewController:self.currentViewController toViewController:vc duration:0.5 options:UIViewAnimationOptionTransitionNone animations:^{
        [self.currentViewController.view removeFromSuperview];
        vc.view.frame = self.contentView.bounds;
        [self.contentView addSubview:vc.view];
        [vc.view addSubview:self.segmentedControl];
    } completion:^(BOOL finished) {
        [vc didMoveToParentViewController:self];
        [self.currentViewController removeFromParentViewController];
        self.currentViewController = vc;
    }];
}

- (UIViewController *)viewControllerForSegmentIndex:(NSInteger)index {
    UIViewController *vc;
    switch (index) {
        case 0:
            vc = self.searchNavController;
            break;
        case 1:
            vc = [[DkTRecentDocketViewController alloc] init];
            break;
    }
    return vc;
}

- (UINavigationController *) searchNavController {
    if(_searchNavController == nil) {
        _searchNavController = [[UINavigationController alloc] initWithRootViewController:[[DkTSearchViewController alloc] init]];
        [_searchNavController setNavigationBarHidden:YES];
    }
    return _searchNavController;
}

-(HMSegmentedControl *) segmentedControl {
    
    if(_segmentedControl == nil) {
        _segmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"Search", @"Recent"]];
        [_segmentedControl setSelectedSegmentIndex:0];
        [_segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
        
        CGFloat y = PAD_OR_POD(15, 5);
        _segmentedControl.frame = CGRectMake(self.view.frame.size.width*.2, y, self.view.frame.size.width*.6, 30);
        _segmentedControl.font = [UIFont fontWithName:kMainFont size:10];
        _segmentedControl.textColor = [UIColor inactiveColor];
        _segmentedControl.selectedTextColor = [UIColor inactiveColor];
        _segmentedControl.selectionIndicatorColor = [UIColor inactiveColor];
        _segmentedControl.selectionIndicatorHeight = 3;
        _segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleTextWidthStrip;
        _segmentedControl.selectionLocation = HMSegmentedControlSelectionLocationDown;
        _segmentedControl.backgroundColor = [UIColor clearColor];
    }
    return _segmentedControl;
    
}


@end

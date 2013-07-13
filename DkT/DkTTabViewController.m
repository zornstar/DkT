//
//  RECAPTabViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTTabViewController.h"
#import "DkTSearchViewController.h"
#import "DkTBookmarkViewController.h"
#import "DkTDocumentsViewController.h"
#import "DkTTabBar.h"

#import "UIImage+Utilities.h"
#import <QuartzCore/QuartzCore.h>

#import "DkTConstants.h"

@interface DkTTabViewController ()
{
    CGRect _contentFrame;
    CGRect _horizontalFrame;
    CGPoint _center;
    
    CGFloat _tabBarHeight;
    CGRect _tabBarFrame;
    
}
@end


@implementation DkTTabViewController

- (id)init
{
    self = [super init];
    if (self) {
        _selectedIndex = NSNotFound;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViewControllers];
    [self setupView];
    [self setSelectedIndex:0];
}

-(void) setupViewControllers
{
    _viewControllers = [NSMutableArray arrayWithCapacity:3];
    
    UINavigationController *navCtr = [[UINavigationController alloc] initWithRootViewController:[[DkTSearchViewController alloc] init]];
    [navCtr setNavigationBarHidden:YES];
    [self.viewControllers addObject:navCtr];
    [self.viewControllers addObject:[[DkTBookmarkViewController alloc] init]];
    [self.viewControllers addObject:[[DkTDocumentsViewController alloc] init]];
}


-(DkTTabBar *)tabBar
{
    if (_tabBar == nil)
    {
        
        CGRect frame = self.view.frame;
        frame.size.height *= kTabBarHeight;
        
        _tabBarHeight = frame.size.height;
        _tabBarFrame = frame;
        
        _tabBar = [[DkTTabBar alloc] initWithSectionTitles:@[@"Search", @"Bookmarks", @"Documents"]];
        _tabBar.sectionImages = @[kSearchImage, kBookmarkImage, kDocumentsImage];
        _tabBar.frame = frame;
        _tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
        _tabBar.backgroundColor = kInactiveColor;
        _tabBar.selectionIndicatorColor = kActiveColor;
        _tabBar.textColor = kDarkTextColor;
        _tabBar.selectedTextColor = kLightTextColor;
        _tabBar.type = HMSegmentedControlTypeCustom;
        _tabBar.selectionStyle = HMSegmentedControlSelectionStyleBox;
        
        __weak typeof(self) weakSelf = self;
        
        [_tabBar setIndexChangeBlock:^(NSInteger index) {
            [weakSelf setSelectedIndex:index];
        }];
    }
    return _tabBar;
}

-(UIView *)contentView
{
    if(_contentView == nil)
    {
        _contentView = [[UIView alloc] initWithFrame:_contentFrame];
        _contentView.backgroundColor = [UIColor whiteColor];
    
    }
    
    return _contentView;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if (selectedIndex != _selectedIndex && selectedIndex < [self.viewControllers count])
    {
        UIViewController *selectedViewController = [self.viewControllers objectAtIndex:selectedIndex];
        [self addChildViewController:selectedViewController];
        
        selectedViewController.view.frame = self.contentView.bounds; //change this if not sizing right
        [self.contentView addSubview:selectedViewController.view];
        // remove previously selected view controller (if any)
        if (_selectedIndex != NSNotFound)
        {
            UIViewController *previousViewController = [self.viewControllers objectAtIndex:_selectedIndex];
            [previousViewController.view removeFromSuperview];
            [previousViewController removeFromParentViewController];
        }
        
        // set new selected index
        _selectedIndex = selectedIndex;
    }
}


-(void) setupView
{
    [self.view addSubview:self.tabBar];
    
    _contentFrame = self.view.frame;
    _contentFrame.size.height*=(1-kTabBarHeight);
    _contentFrame.origin.y = CGRectGetMaxY(self.tabBar.frame);
    _horizontalFrame = CGRectMake(0, 0, _contentFrame.size.height, _contentFrame.size.width);
    [self.view addSubview:self.contentView];
    _center = self.contentView.center;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    
    
    CGRect applicationFrame = [UIScreen mainScreen].applicationFrame;
    UIImageView *tabBarImageView = [UIImage imageViewWithView:self.tabBar];
    [self.view addSubview:tabBarImageView];
    
    self.tabBar.layer.anchorPoint = CGPointMake(0, 0);
    if(UIInterfaceOrientationIsPortrait(fromInterfaceOrientation))
    {
        
        CGRect frame = self.tabBar.frame;
        frame.origin = CGPointMake(applicationFrame.size.height - kTabBarHeight*2, 0);
        self.tabBar.frame = frame;
        self.tabBar.layer.anchorPoint = CGPointMake(0, 0);
        CGAffineTransform m = CGAffineTransformMakeRotation(M_PI_2);
        self.tabBar.layer.transform = CATransform3DMakeAffineTransform(m);
        //self.contentView.hidden = YES;
        [self.view sendSubviewToBack:self.tabBar];
        [self.view sendSubviewToBack:tabBarImageView];
    
    [UIView animateWithDuration:.4 animations:^{
        
        self.contentView.frame = CGRectMake(0, 0, applicationFrame.size.height-_tabBarHeight, applicationFrame.size.width);
        
        CGRect newFrame = self.tabBar.frame;
        newFrame.origin = CGPointMake(applicationFrame.size.height, 0);
        self.tabBar.frame  = newFrame;
       // self.tabBar.layer.anchorPoint = CGPointMake(0, 0);
       //self.tabBar.layer.transform = CATransform3DMakeRotation(M_PI_2, 1, 0, 0);
        tabBarImageView.frame = CGRectMake(tabBarImageView.frame.origin.x, 2*CGRectGetMaxY(tabBarImageView.frame), tabBarImageView.frame.size.width, tabBarImageView.frame.size.height);
        
    } completion:^(BOOL finished) {
        
        [tabBarImageView removeFromSuperview];
    }];
        
    
    }
    
    else
    {
        
        self.tabBar.layer.transform = CATransform3DMakeRotation(0, 0, 0, 0);
        self.tabBar.frame = CGRectMake(applicationFrame.size.height, applicationFrame.size.height*20, applicationFrame.size.height, _tabBarHeight);
        
        CGRect frame = [self horizontalTabFrame];
        frame.origin.y = self.contentView.frame.origin.y;
        self.tabBar.frame = frame;
        
        [self.view sendSubviewToBack:self.tabBar];
        
        [UIView animateWithDuration:.4 animations:^{
            
            self.contentView.frame = _contentFrame;
            self.tabBar.frame = [self horizontalTabFrame];
            
        } completion:^(BOOL finished) {
            
            [tabBarImageView removeFromSuperview];
        }];
        
    }
    
    
}

-(CGRect) horizontalTabFrame
{
    return _tabBarFrame;
}

-(CGRect) verticalTabFrame
{
    
}
@end

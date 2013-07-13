//
//  RECAPSettingsChildViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 6/25/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSettingsChildViewController.h"
#import "DkTSettingsCell.h"
#import <QuartzCore/QuartzCore.h>

@interface DkTSettingsChildViewController ()


@property (nonatomic, strong) UIControl *button;
@property (nonatomic) CGPoint origin;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;

@end

@implementation DkTSettingsChildViewController

- (id)initWithSettingsCell:(DkTSettingsCell *)cell
{
    
    if (self = [super init]) {
        
        self.containerView = [[UIView alloc] init];
        self.containerView.frame = cell.frame;
        self.origin = cell.frame.origin;
        self.cell = cell;
        [self.cell invert];
        self.cell.frame = CGRectMake(0, 0, self.cell.frame.size.width, self.cell.frame.size.height);
        self.button = [[UIControl alloc] initWithFrame:cell.frame];
        [self.button addSubview:self.cell];
        self.cell.userInteractionEnabled = NO;
        [self.button addTarget:self action:@selector(dismissSettingsChildViewController:) forControlEvents:UIControlEventTouchUpInside];
        [self.containerView addSubview:self.button];
        self.frame = CGRectZero;
        self.containerView.backgroundColor = kActiveColor;
        
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self.view addSubview:self.containerView];
    self.containerView.layer.cornerRadius = 5.0;
    
    
    [self expandContainerToFrame:self.frame animationInterval:.5 completion:^(BOOL finished) {
       
        //add pinch
        
        self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSettingsChildViewController:)];
        
        [self.view addGestureRecognizer:self.pinchGestureRecognizer];
        
        if(self.contentView) [self.containerView addSubview:self.contentView];
        
        
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) expandContainerToFrame:(CGRect)frame animationInterval:(NSTimeInterval)interval completion:(void (^)(BOOL finished))completion
{
    CGFloat x =  (self.position % 2 == 0) ? 0 : frame.size.width - self.cell.frame.size.width;
    
    CGFloat y = (self.position < 2) ? 0 : frame.size.height - self.cell.frame.size.height;
    
    CGRect cellFrame = CGRectMake(x, y, self.cell.frame.size.width, self.cell.frame.size.height);
    
    [UIView animateWithDuration:interval animations:^{
        
        self.containerView.frame = frame;
        self.cell.frame = cellFrame;
        
    } completion:completion];
}

-(void) dismissSettingsChildViewController:(id)sender
{
    if([sender isKindOfClass:[UIPinchGestureRecognizer class]])
    {
        if(((UIPinchGestureRecognizer *)sender).state == UIGestureRecognizerStateBegan)
        {
            [self.view removeGestureRecognizer:sender];
            
            [self dismiss];
        }
    }
    
    else
    {
        [self dismiss];
    }
}

-(void) dismiss
{
    CGRect frame = CGRectMake(self.origin.x, self.origin.y, self.cell.frame.size.width, self.cell.frame.size.height);
    
    if(self.contentView.superview) [self.contentView removeFromSuperview];
    
    [UIView animateWithDuration:.5 animations:^{
        
        self.containerView.frame = frame;
        self.cell.frame = CGRectMake(0, 0, self.cell.frame.size.width, self.cell.frame.size.height);
        
    } completion:^(BOOL finished) {
        
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];

}

@end

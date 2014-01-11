//
//  DkTAboutViewController.m
//  DkT
//
//  Created by Matthew Zorn on 7/31/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTAboutViewController.h"

@interface DkTAboutViewController ()

@end

@implementation DkTAboutViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setup];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) setup
{
    
    NSString *aboutString = @"DkT is an iOS app that interfaces with PACER to help browse, manage, and share federal court dockets and documents with greater ease and less expense.\n\nDkT is  free and open-source, but normal PACER charges apply.  DkT is not affiliated with PACER or any other institution, and does not store or send  personal data except for use with PACER.\n\nGo to www._.com for more information.";
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:aboutString];
    UITextView *aboutView = [[UITextView alloc] initWithFrame:CGRectZero];
    aboutView.attributedText = attrString;
    aboutView.textAlignment = NSTextAlignmentJustified;
    aboutView.backgroundColor = [UIColor clearColor];
    aboutView.textColor = [UIColor inactiveColor];
    aboutView.font = [UIFont fontWithName:kMainFont size:10];
    aboutView.frame = CGRectMake(PAD_OR_POD(5,self.cell.frame.size.width), self.containerView.frame.size.height*.05, self.containerView.frame.size.width-(PAD_OR_POD(10,self.cell.frame.size.width*1.02)), self.containerView.frame.size.height*.9);
    aboutView.editable = NO;
    IOS7(aboutView.selectable = NO;,);
    self.contentView = aboutView;
    
    [self.containerView bringSubviewToFront:self.button];
}


@end

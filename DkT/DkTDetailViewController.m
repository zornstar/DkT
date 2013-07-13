//
//  RECAPDetailViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDetailViewController.h"
#import "DkTDocumentManager.h"
#import "DkTDocket.h"
#import "DkTDocketEntry.h"
#import "UIImage+Utilities.h"
#import "DkTDocumentManager.h"

@interface DkTDetailViewController ()
{
    UIButton *_docketButton;
    UIBarButtonItem *_mailBarButtonItem;
    UIBarButtonItem *_saveBarButtonItem;
    UIBarButtonItem *_backBarButtonItem;
    UIBarButtonItem *_space;
}

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation DkTDetailViewController

- (id)init
{
    if(self = [super init])
    {
        _isLocal = FALSE;
    }
    
    return self;
}

-(void) viewDidLoad
{
    self.view.backgroundColor = kInactiveColor;
    UIImage *backImage = [[UIImage imageNamed:@"flipArrow"] imageWithColor:kInactiveColor];
    UIImage *saveImage = [[UIImage imageNamed:@"documentAdd"] imageWithColor:kInactiveColor];
    UIImage *mailImage = [[UIImage imageNamed:@"mail"] imageWithColor:kInactiveColor];
    
    
    CGRect bbFrame = CGRectMake(0,0,kToolbarIconSize.width,kToolbarIconSize.height);
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = bbFrame;
    [backButton setBackgroundImage:backImage forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    _backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    UIButton *mailButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mailButton.frame = bbFrame;
    [mailButton setBackgroundImage:mailImage forState:UIControlStateNormal];
    [mailButton addTarget:self action:@selector(mail) forControlEvents:UIControlEventTouchUpInside];
    _mailBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:mailButton];
    
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = bbFrame;
    [saveButton setBackgroundImage:saveImage forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    _saveBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
    
    _space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    _space.width = kToolbarIconSize.width;
    
    self.navigationItem.rightBarButtonItems = @[_backBarButtonItem];
    
    UIImage *docket = [[UIImage imageNamed:@"docket"] imageWithColor:kInactiveColor];
    UIButton *docketButton = [UIButton buttonWithType:UIButtonTypeCustom];
    docketButton.frame = bbFrame;
    [docketButton setBackgroundImage:docket forState:UIControlStateNormal];
    _docketButton = docketButton;
    
    self.navigationItem.titleView = [self titleLabel];
    
}

-(void) toggleButtonVisibility
{
    if(self.isLocal)
    {
        self.navigationItem.rightBarButtonItems =  @[_backBarButtonItem, _space, _mailBarButtonItem];
    }
    
    else if (self.filePath.length > 0) {
        self.navigationItem.rightBarButtonItems =  @[_backBarButtonItem, _space, _saveBarButtonItem, _space, _mailBarButtonItem];
    }
    
    else {
        self.navigationItem.rightBarButtonItems = @[_backBarButtonItem];
    }
    

}

-(UILabel *) titleLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = self.title;
    label.numberOfLines = 2;
    label.textColor = kInactiveColor;
    label.font = [UIFont fontWithName:kMainFont size:13];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    [label sizeToFit];
    return label;
}


- (void)setDetailItem:(id)newDetailItem
{
    
    [self configureView];
    
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

-(void) configureView
{
    
}


-(void) dismiss
{
    if(!self.isLocal)
    [self.parentViewController.parentViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
    
    else
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) save
{
    [DkTDocumentManager saveDocumentAtTempPath:self.filePath toSavedDocket:self.docket];
}

-(void) mail
{
    if([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        [mailVC setSubject:[NSString stringWithFormat:@"%@ (%d)", self.title, self.docketEntry.entry]];
        [mailVC setMessageBody:[NSString stringWithFormat:@"%@ - Docket Entry %d", self.title, self.docketEntry.entry] isHTML:NO];
        
        NSData *data = [NSData dataWithContentsOfFile:self.filePath];
        [mailVC addAttachmentData:data mimeType:@"application/pdf" fileName:[NSString stringWithFormat:@"%d - %@", self.docketEntry.entry, self.title]];
        mailVC.mailComposeDelegate = self;
        
        [self presentViewController:mailVC animated:YES completion:^{
            
        }];
    }
    
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    
    [_docketButton addTarget:barButtonItem.target action:barButtonItem.action forControlEvents:UIControlEventTouchUpInside];
     self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_docketButton];
    
   self.masterPopoverController = popoverController;
    
    
    
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    
    
    self.masterPopoverController = nil;
}

-(BOOL) splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);

}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

-(void) setFilePath:(NSString *)filePath
{
    _filePath = filePath;
    
    [self toggleButtonVisibility];
}



@end

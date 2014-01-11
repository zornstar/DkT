
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDetailViewController.h"
#import "DkTDocumentManager.h"
#import "DkTDocket.h"
#import "DkTDocketEntry.h"
#import "UIImage+Utilities.h"
#import "DkTDocumentManager.h"
#import "PKRevealController.h"
#import "DkTImageCache.h"


@interface DkTDetailViewController ()
{
    
}

@property (strong, nonatomic) UIBarButtonItem *mailBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *saveBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *backBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *actionBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *space;
@property (strong, nonatomic) UIPopoverController *actionPopoverController;
@property (strong, nonatomic) UIActivityViewController *activityController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (nonatomic, readonly, getter = hasAppeared) BOOL appeared;

@end

@implementation DkTDetailViewController


-(void) viewDidLoad
{
    self.view.backgroundColor = [UIColor inactiveColor];
    self.contentSizeForViewInPopover = CGSizeMake(150, 140);
    
    UIImage *saveImage = [[DkTImageCache sharedCache] imageNamed:@"documentAdd" color:[UIColor inactiveColor]];
    UIImage *mailImage = [[DkTImageCache sharedCache] imageNamed:@"mail" color:[UIColor inactiveColor]];
    UIImage *actionImage = [[DkTImageCache sharedCache] imageNamed:@"action" color:[UIColor inactiveColor]];
    
    CGFloat hw = PAD_OR_POD(30, 25);
    
    CGRect bbFrame = CGRectMake(0,0,hw,hw);
    
    UIButton *mailButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mailButton.frame = bbFrame;
    [mailButton setBackgroundImage:mailImage forState:UIControlStateNormal];
    [mailButton addTarget:self action:@selector(mail) forControlEvents:UIControlEventTouchUpInside];
    mailButton.helpText = @"E-mail the document.";
    self.mailBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:mailButton];
    
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = bbFrame;
    [saveButton setBackgroundImage:saveImage forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    saveButton.helpText = @"Save the document.";
    self.saveBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
    
    
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame = CGRectMake(0, 0, hw, hw/1.2);
    [actionButton setBackgroundImage:actionImage forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];
    self.actionBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
    
    self.space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    self.space.width = PAD_OR_POD(kToolbarIconSize.width, kToolbarIconSize.width/2.5);
    
    
    UIImage *docket = [[DkTImageCache sharedCache] imageNamed:@"back" color:[UIColor inactiveColor]];
    UIButton *docketButton = [UIButton buttonWithType:UIButtonTypeCustom];
    docketButton.frame = bbFrame;
    [docketButton setBackgroundImage:docket forState:UIControlStateNormal];
    self.docketButton = docketButton;
    
    [self toggleButtonVisibility];
}

-(void) setTitle:(NSString *)title
{
    [super setTitle:title];
    self.navigationItem.titleView = [self titleLabel];
}

-(void) viewWillAppear:(BOOL)animated
{
    [self toggleButtonVisibility];
    
    if(!self.file)
    {
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.docketButton addTarget:[self splitViewController] action:@selector(toggleMasterVisible:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        else
        {
            [self.docketButton addTarget:self action:@selector(revealPanel:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    else
    {
        [self.docketButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if(self.file || UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_docketButton];
    }
    
}

-(void) viewDidAppear:(BOOL)animated
{
    if(!self.hasAppeared)
    {
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) [self revealPanel:nil];
        
        else if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])){
            [self.splitViewController performSelector:@selector(toggleMasterVisible:)];
        }
    }
    _appeared = YES;
}
-(void) toggleButtonVisibility
{
    NSMutableArray *buttons =  [NSMutableArray array];
    
    if(self.filePath != nil)
    {
        if([[PACERClient sharedClient] networkReachabilityStatus] != AFNetworkReachabilityStatusNotReachable)
        {
            [buttons addObjectsFromArray:@[self.mailBarButtonItem, self.space]];
        }
        if(!self.file)
        {
            [buttons addObjectsFromArray:@[self.saveBarButtonItem, self.space]];
        }
        
        [buttons addObjectsFromArray:@[self.actionBarButtonItem]];
        
    }
    
     
    self.navigationItem.rightBarButtonItems = buttons;

}

-(UILabel *) titleLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = self.title;
    label.numberOfLines = 2;
    label.textColor = [UIColor inactiveColor];
    label.font = [UIFont fontWithName:kMainFont size:13];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = .8;
    [label sizeToFit];
    
    
    return label;
}


-(void) dismiss
{
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
    [DkTDocumentManager saveDocketEntry:self.docketEntry atTempPath:self.filePath];
}

-(void) revealPanel:(id)sender
{
    [self.navigationController.revealController showViewController:self.navigationController.revealController.leftViewController animated:YES completion:^(BOOL finished) {
        
    }];
}

-(void) mail
{
    if([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        
        NSString *subject;
        
        mailVC.title = self.title;
        
        if (self.file)
        {
            self.filePath = [self.file objectForKey:DkTFilePathKey];
            NSString *docketName = [[self.filePath stringByDeletingLastPathComponent] lastPathComponent];
            docketName = decodeFromPercentEscapeString(docketName);
            subject = [NSString stringWithFormat:@"%@ - %@", docketName, self.title];
            [mailVC setMessageBody:[self.file objectForKey:DkTFileSummaryKey] isHTML:NO];
            NSData *data = [NSData dataWithContentsOfFile:self.filePath];
            [mailVC addAttachmentData:data mimeType:@"application/pdf" fileName:[NSString stringWithFormat:@"%@ - %@", docketName, [self.file objectForKey:DkTFileEntryKey]]];
            
        }
        
        else
        {
            subject = [NSString stringWithFormat:@"%@ - %@", self.docketEntry.docket.name, self.title];
            [mailVC setMessageBody:self.docketEntry.summary isHTML:YES];
            NSData *data = [NSData dataWithContentsOfFile:self.filePath];
            NSString *fileName = [NSString stringWithFormat:@"%@ - %@.pdf", self.docketEntry.docket.name, self.docketEntry.entryNumber];
            [mailVC addAttachmentData:data mimeType:@"application/pdf" fileName:fileName];
        }
        
        [mailVC setSubject:subject];
        
        [mailVC.navigationBar setTitleTextAttributes:@{UITextAttributeTextColor:[UIColor inactiveColor]}];
        [mailVC.navigationBar setTintColor:[UIColor inactiveColor]];
        
        
        
        
        for(UINavigationItem *i in mailVC.navigationBar.items)
        {
            
            IOS7([i.leftBarButtonItem setTintColor:[UIColor whiteColor]];
                 [i.rightBarButtonItem setTintColor:[UIColor whiteColor]];
                 [i.backBarButtonItem setTintColor:[UIColor whiteColor]];, )
            
        }
        
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
    
    if(!self.file) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_docketButton];
    }
    
    
   _masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    
    self.navigationItem.leftBarButtonItem = nil;
    _masterPopoverController = nil;
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

-(UIActivityViewController *) activityController
{
    
    __weak DkTDetailViewController *weakSelf = self;
    
    if(_activityController == nil)
    {
            NSURL *url = [NSURL fileURLWithPath:self.filePath];
            NSArray *data = @[url];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:data
                                                                                     applicationActivities:nil];
        
        
        
        NSMutableArray *excludedActivities = [@[UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter,UIActivityTypePostToWeibo, UIActivityTypeSaveToCameraRoll, UIActivityTypeMail] mutableCopy];
        
        IOS7([excludedActivities addObject:UIActivityTypeAddToReadingList];, );
        IOS7([excludedActivities addObject:UIActivityTypePostToVimeo];, );
        IOS7([excludedActivities addObject:UIActivityTypePostToFlickr];, );
        IOS7([excludedActivities addObject:UIActivityTypePostToTencentWeibo];, );
        
        
        if(![UIPrintInteractionController canPrintURL:url]) [excludedActivities addObject:UIActivityTypePrint];
       
        activityVC.excludedActivityTypes = excludedActivities;
        
        
        activityVC.completionHandler = ^(NSString *activityType, BOOL completed) {
            
          // if(activityType == UIActivityTypePrint) [self print];
            
            if(activityType == UIActivityTypeMail) [weakSelf mail];
    
        };
        
        _activityController = activityVC;
        
        
    }
    
    return _activityController;
}

-(UIPopoverController *) actionPopoverController
{
    if(_actionPopoverController == nil)
    {
        _actionPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.activityController];
        _actionPopoverController.delegate = self;
    }
    
    return _actionPopoverController;
}
-(void) action:(id)sender
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (_actionPopoverController == nil) {
            //The color picker popover is not showing. Show it.
            [self.actionPopoverController presentPopoverFromBarButtonItem:[self.navigationItem.rightBarButtonItems lastObject]
                                                 permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        } else {
            [self.actionPopoverController dismissPopoverAnimated:YES];
        }
    }
    
    else
    {
        [self presentViewController:self.activityController animated:YES completion:nil];
    }
    
    
}

-(void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if(popoverController == self.actionPopoverController) self.actionPopoverController = nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
    if(_actionPopoverController) [self.actionPopoverController dismissPopoverAnimated:YES];
    
    if([self.masterPopoverController isPopoverVisible])
    {
        [self.splitViewController performSelector:@selector(toggleMasterVisible:)];
        self.masterPopoverController = nil;
    }
}

@end

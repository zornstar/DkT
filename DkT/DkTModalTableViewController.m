//
//  DkTModalTableViewController.m
//  DkT
//
//  Created by Matthew Zorn on 8/14/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTModalTableViewController.h"
#import "MBProgressHUD.h"
#import "ReaderViewController.h"
#import "DkTSession.h"
#import "DkTDocketEntry.h"
#import "DkTAlertView.h"
#import "PACERClient.h"
#import "RECAPClient.h"
#import "PSMenuItem.h"
#import "DkTBookmarkDetailViewController.h"

@interface DkTModalTableViewController ()

@end

@implementation DkTModalTableViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.toolbarItems = nil;
    self.navigationItem.rightBarButtonItem = nil;
    [PSMenuItem installMenuHandlerForObject:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - overrides

-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path
{
    [self didDownloadDocketEntry:entry atPath:path cost:YES];
}

-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path cost:(BOOL)paid
{
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.docketEntries indexOfObject:entry] inSection:0]];
    [MBProgressHUD hideAllHUDsForView:cell animated:YES];
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    //handle a downloaded document
    
    //path: local path of the file
    //entry: a docket entry object corresponding to the docket entry
    
    
    NSLog(@"%@",path);
    ReaderDocument *readerDocument = [[ReaderDocument alloc] initWithFilePath:path password:nil];
    ReaderViewController *pdfReader = [[ReaderViewController alloc] initWithReaderDocument:readerDocument];
    
    //PACER Opinions are free.
    //If the first word of the entry is not equal to OPINION, then we must add its cost;
    if(paid)
    {
        if(![[[entry.summary componentsSeparatedByString:@" "] objectAtIndex:0] isEqualToString:@"OPINION"])
        {
            dispatch_async(dispatch_queue_create("cost.queue", NULL), ^{
                [DkTSession addCostForPages:readerDocument.pageCount.intValue];
            });
        }
    }
    
    DkTBookmarkDetailViewController *detailController = [[DkTBookmarkDetailViewController alloc] init];
    pdfReader.view.frame = detailController.view.frame;
    [detailController addChildViewController:pdfReader];
    [detailController.view addSubview:pdfReader.view];
    [detailController setDocketEntry:entry];
    [detailController setFilePath:path];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:detailController];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:nav animated:YES completion:^{
        
    }];
    
    
}

-(void) handleDocumentsFromDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry entries:(NSArray *)entries
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.docketEntries indexOfObject:entry] inSection:0]];
    [MBProgressHUD hideAllHUDsForView:cell animated:YES];
    
    DkTModalTableViewController *nextController = [[DkTModalTableViewController alloc] init];
    nextController.title = [NSString stringWithFormat:@"Entry #%d", entry.entry.intValue];
    nextController.docketEntries = entries;
    nextController.root = NO;
    nextController.docket = self.docket;
    
    [self.navigationController pushViewController:nextController animated:YES];
}

-(void) handleSealedDocument:(DkTDocketEntry *)entry
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.docketEntries indexOfObject:entry] inSection:0]];
    [MBProgressHUD hideAllHUDsForView:cell animated:YES];
    
    DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Entry Sealed" andMessage:@"Docket entry under seal"];
    
    [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
        
        [alertView dismissAnimated:YES];
        
    }];
}

-(void) handleDocketEntryError:(DkTDocketEntry *)entry
{
    DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Error" andMessage:@"Error loading entry."];
    
    [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
        
        [alertView dismissAnimated:YES];
        
    }];
    
    [alertView show];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //Code for dissmissing this viewController by clicking outside it
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
    [self.view.window addGestureRecognizer:recognizer];
    
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [sender locationInView:nil]; //Passing nil gives us coordinates in the window
        
        //Then we convert the tap's location into the local view's coordinate system, and test to see if it's in or outside. If outside, dismiss the view.
        
        if (![self.tableView pointInside:[self.tableView convertPoint:location fromView:self.view.window] withEvent:nil])
        {
            // Remove the recognizer first so it's view.window is valid.
            [self.view.window removeGestureRecognizer:sender];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                
            }];
        }
    }
}

@end

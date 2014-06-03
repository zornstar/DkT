
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDocumentsViewController.h"
#import "DkTDetailViewController.h"
#import "ReaderViewController.h"
#import "UIImage+Utilities.h"
#import "UIView+Utilities.h"
#import "DkTSettings.h"
#import "DkTAlertView.h"
#import "DkTButtonCell.h"
#import "FSButton.h"
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "PKRevealController.h"

typedef enum {DkTDocumentOperationBundling = -1, DkTDocumentOperationNone = 0, DkTDocumentOperationZipping = 1} DkTDocumentOperations;

@interface DkTDocumentsViewController ()

@property (nonatomic, strong) NSIndexPath *batchPath;
@property (nonatomic, strong) NSIndexPath *zipPath;
@property (nonatomic, strong) NSMutableArray *dockets;
@property (nonatomic, strong) UIDocumentInteractionController *doccontroller;
@property (nonatomic, strong) UILabel *noDocumentLabel;
@property (nonatomic, strong) NSMutableArray *batching;


@end

@implementation DkTDocumentsViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        self.dockets = [[DkTDocumentManager sharedManager] dockets];
        
        [DkTDocumentManager setDelegate:self];
        _batchPath = nil; _zipPath = nil;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor activeColor];
    [self.view addSubview:self.tableView];
    
    self.noDocumentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.center.y-30, self.view.frame.size.width, 24)];
    self.noDocumentLabel.text = @"You have no saved documents.";
    self.noDocumentLabel.textColor = [UIColor inactiveColor];
    self.noDocumentLabel.backgroundColor = [UIColor clearColor];
    self.noDocumentLabel.font = [UIFont fontWithName:kMainFont size:PAD_OR_POD(16, 12)];
    self.noDocumentLabel.textAlignment = NSTextAlignmentCenter;
    self.noDocumentLabel.hidden = (self.dockets > 0);
    self.noDocumentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.noDocumentLabel];
    
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) [PSMenuItem installMenuHandlerForObject:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
    [self resizeTableView];
}



-(void) scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

-(void) resizeTableView
{
    self.tableView.frame = self.view.frame;
   
    NSInteger rows = 0;
    
    for(int i = 0; i < [self.tableView numberOfSections]; ++i)
    {
        rows += [self tableView:self.tableView numberOfRowsInSection:i];
    }
    
    CGRect frame;
    frame.size.width = self.view.frame.size.width*.85;
    frame.origin = CGPointMake((self.view.frame.size.width-frame.size.width)/2.0,(self.view.frame.size.width-frame.size.width)/2.0);
    frame.size.height = MIN(self.tableView.rowHeight*rows+5*self.tableView.numberOfSections, self.view.frame.size.height-frame.origin.y);
    
    self.tableView.frame = frame;
    
    self.tableView.frame = CGRectInset(self.view.frame, 15, 15);
}




-(void) zipIndexPath:(NSIndexPath*)indexPath
{
    if(self.zipPath != nil)
    {
        DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Busy" andMessage:@"Currently zipping another docket."];
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            [alertView dismissAnimated:YES];
        }];
        
        [alertView show];
        return;
    }
    
    self.zipPath = indexPath;
        
    DkTDocketFile *docketDict = [self.dockets objectAtIndex:indexPath.section];
    NSString *docketPath = [[DkTDocumentManager docketsFolder] stringByAppendingPathComponent:[docketDict objectForKey:DkTFileDocketNameKey]];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    
    if(cell.accessoryView == nil) cell.accessoryView = [self activityIndicator];
    
    __weak DkTDocumentsViewController *weakSelf = self;
    
    dispatch_async(dispatch_queue_create("com.DkT.zip", 0), ^{
        
        NSString *str = [DkTDocumentManager zipDocketAtPath:docketPath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.zipPath = nil;
            [(UIActivityIndicatorView *)cell.accessoryView stopAnimating];
            cell.accessoryView = nil;
            
            MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
            
            NSString *subject = decodeFromPercentEscapeString([docketPath lastPathComponent]);
            
            [mailVC setSubject:subject];
            
            [mailVC.navigationBar setTitleTextAttributes:@{UITextAttributeTextColor:[UIColor inactiveColor]}];
            [mailVC.navigationBar setTintColor:[UIColor activeColorLight]];
            for(UINavigationItem *i in mailVC.navigationBar.items)
            {
                
                IOS7([i.leftBarButtonItem setTintColor:[UIColor whiteColor]];
                     [i.rightBarButtonItem setTintColor:[UIColor whiteColor]];
                     [i.backBarButtonItem setTintColor:[UIColor whiteColor]];, )
                
            }
            NSData *data = [NSData dataWithContentsOfFile:str];
            [mailVC addAttachmentData:data mimeType:@"application/zip" fileName:decodeFromPercentEscapeString([str lastPathComponent])];
            mailVC.mailComposeDelegate = weakSelf;
            
            [weakSelf presentViewController:mailVC animated:YES completion:^{
                
                
            }];
            
        });
    });

}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


-(void) batchDocuments:(NSIndexPath *)indexPath
{
    DkTDocketFile *docketDict = [self.dockets objectAtIndex:indexPath.section];
    DkTButtonCell *cell = (DkTButtonCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    if(self.batchPath != nil)
    {
        DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Busy" andMessage:@"Currently bundling another docket."];
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            [alertView dismissAnimated:YES];
        }];
        
        [alertView show];
        return;
    }
    
    self.batchPath = indexPath;
    if(cell.accessoryView == nil)
    {
        cell.accessoryView = [self activityIndicator];
        
        dispatch_async(dispatch_queue_create("batch.com.DkT",0), ^{
            
            BOOL TOC = [[[DkTSettings sharedSettings] valueForKey:DkTSettingsAddTOCKey] boolValue];
            
            DkTBatchOptions options = (TOC) ? (DkTBatchOptionsPageNumbers | DkTBatchOptionsTOC) : DkTBatchOptionsNone;
            
            [DkTDocumentManager joinDocketNamed:[docketDict objectForKey:DkTFileDocketNameKey] destination:NSTemporaryDirectory() batchOptions:options completion:^(id filepath) {
                
                self.batchPath = nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [(UIActivityIndicatorView *)cell.accessoryView stopAnimating];
                    cell.accessoryView = nil;
                    NSURL *url = [NSURL fileURLWithPath:filepath];
                    _doccontroller = [UIDocumentInteractionController interactionControllerWithURL:url];
                    _doccontroller.delegate = self;
                    
                    CGRect targetRect = cell.contentView.frame;
                    targetRect.origin = [self.view convertPoint:targetRect.origin fromView:self.tableView];
                    
                    if (self.view.window != nil)
                        if(![_doccontroller presentOpenInMenuFromRect:targetRect inView:self.view animated:YES])
                        {
                            DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"No PDF Application" andMessage:@"You do not have an external application for reading pdfs."];
                            [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                                [alertView dismissAnimated:YES];
                            }];
                            
                            [alertView show];
                        }
                        
                    
                });
            }];
            
            
        });

    }
}

-(UITableView *) tableView
{
    if(_tableView == nil)
    {
        CGRect frame = CGRectInset(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height), 0, 0);
        _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        _tableView.rowHeight = PAD_OR_POD(65, 60);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        //_tableView.clipsToBounds = YES;
        _tableView.bounces = NO;
        IOS7(_tableView.separatorInset = UIEdgeInsetsZero;,);
        _tableView.scrollEnabled = YES;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.separatorColor = [UIColor darkerTextColor];
        _tableView.backgroundColor = [UIColor activeColor];
        
        
    }
    
    return _tableView;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger n = self.dockets.count;
    self.noDocumentLabel.hidden = (n > 0);
    return n;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 5.0f;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *sectionDictionary = [self.dockets objectAtIndex:section];
    
    NSInteger fileCount = [[sectionDictionary objectForKey:@"files"] count];
    
    return [[sectionDictionary objectForKey:@"collapsed"] boolValue] ? 1 : fileCount + 1;
    
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row > 0) return 2;
    
    else return 0;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    DkTButtonCell *cell;
    
    
    NSMutableDictionary *sectionDictionary = [self.dockets objectAtIndex:indexPath.section];
    
    
    if(indexPath.row == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TopCell"];
        
        if(cell == nil)
        {
            cell = [[DkTButtonCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TopCell"];
            
            cell.textLabel.font = [UIFont fontWithName:kMainFont size:PAD_OR_POD(17, 14)];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.minimumScaleFactor = .8;
            cell.cornerRadius = 5.0f;
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.textColor = [UIColor darkerTextColor];
            cell.detailTextLabel.textColor = [UIColor lighterTextColor];
            cell.imageView.image = [kFolderImage imageWithColor:[UIColor darkerTextColor]];
            cell.contentView.opaque = YES;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            [cell.contentView addGestureRecognizer:self.longPress];
            cell.helpText = @"Press and hold to bundle documents into one pdf, or to create a zip file with all documents.";
        }
        
        BOOL collapsed = [[sectionDictionary objectForKey:@"collapsed"] boolValue];
        cell.clipsToBounds = NO;
        cell.contentView.backgroundColor = collapsed ? [UIColor inactiveColor] : [UIColor inactiveColorDark];
        cell.backgroundColor = collapsed ? [UIColor inactiveColor] : [UIColor inactiveColorDark];
        cell.textLabel.text = [sectionDictionary objectForKey:DkTFileDocketNameKey];
        cell.backgroundView = [[UIView alloc] init];
        cell.backgroundView.backgroundColor = cell.contentView.backgroundColor;
        
        BOOL aiv = FALSE;
        
        if( (self.batchPath != nil) && ([indexPath compare:self.batchPath] == NSOrderedSame)) aiv = TRUE;
        if( (self.zipPath != nil) && ([indexPath compare:self.zipPath] == NSOrderedSame)) aiv = TRUE;
        
        cell.accessoryView = aiv ? [self activityIndicator]: nil;
        
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            
            CGFloat unit = self.tableView.rowHeight*.9;
            
            FSButton *exportButton = [FSButton buttonWithIcon:[UIImage imageNamed:@"action"] colors:@[[UIColor clearColor], [UIColor activeColor]] title:@"" actionBlock:^{
                
                [self batchDocuments:indexPath];
            }];
            exportButton.frame = CGRectMake(0,0, unit, unit);
            
            FSButton *zipDocket = [FSButton buttonWithIcon:[UIImage imageNamed:@"clip"] colors:@[[UIColor clearColor], [UIColor activeColor]] title:@"" actionBlock:^{
                
                [self zipIndexPath:indexPath];
            }];
            
            zipDocket.frame = CGRectMake(unit,0, unit, unit);
            
            CGFloat width = cell.contentView.frame.size.width - unit*2;
            cell.textLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
            exportButton.backgroundColor = [UIColor clearColor];
            cell.buttonView = [[UIView alloc] initWithFrame:CGRectMake(width, self.tableView.rowHeight/2. - unit/2., unit*2, unit)];
            cell.buttonView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [cell.buttonView addSubview:exportButton];
            [cell.buttonView addSubview:zipDocket];
            cell.buttonView.layer.borderWidth = 0.0f;
            [cell.contentView addSubview:cell.buttonView];
            
        }
        
        else
        {
             [PSMenuItem installMenuHandlerForObject:self.tableView];
        }

    }
    
    else
    {
        
        NSString *identifier = (indexPath.row == [self.tableView numberOfRowsInSection:indexPath.section] - 1) ? @"BottomCell" : @"BodyCell";
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        if(cell == nil)
        {
            cell = [[DkTButtonCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
            cell.cornerRadius = 5.0f;
            cell.textLabel.font = [UIFont fontWithName:kMainFont size:PAD_OR_POD(15, 13)];
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.textLabel.textColor = [UIColor activeColor];
            cell.detailTextLabel.font = [UIFont fontWithName:kContrastFont size:PAD_OR_POD(11, 9)];
            cell.detailTextLabel.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.textColor = [UIColor darkerTextColor];
            cell.detailTextLabel.numberOfLines = PAD_OR_POD(1, 2);
            cell.contentView.backgroundColor = [UIColor inactiveColor];
            cell.contentView.layer.borderWidth = 0.0f;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.imageView.image = [kDocumentIcon imageWithColor:[UIColor activeColor]];
            cell.imageView.transform = CGAffineTransformMakeScale(.5f, .5f);
            cell.accessoryView.backgroundColor = [UIColor clearColor];
            cell.backgroundColor = [UIColor inactiveColor];
            //cell.backgroundView = [[UIView alloc] init];
            //cell.backgroundView.backgroundColor = [UIColor clearColor];
            
            [cell.contentView addGestureRecognizer:self.longPress];
            //cell.contentView.opaque = YES;

             cell.helpText = @"Press to view document.\n\nPress the export document to another pdf reader.";
        }
   
        DkTFile *file = [[sectionDictionary objectForKey:DkTFileDocketFilesKey] objectAtIndex:indexPath.row - 1];
        cell.textLabel.text = [[[file objectForKey:DkTFilePathKey] lastPathComponent] stringByDeletingPathExtension];
        cell.detailTextLabel.text = [file objectForKey:DkTFileSummaryKey];
    
        cell.backgroundView = [[UIView alloc] init];
        cell.backgroundView.backgroundColor = cell.contentView.backgroundColor;
        
    }
    
    return cell;
    
}

-(UIActivityIndicatorView *) activityIndicator
{
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.backgroundColor = [UIColor clearColor];
    spinner.frame = CGRectMake(0, 0, 24, 24);
    [spinner startAnimating];
    return spinner;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] init];
    
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return PAD_OR_POD(65, 60);
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(indexPath.row == 0)
    {
        NSMutableDictionary *sectionDictionary = [self.dockets objectAtIndex:indexPath.section];
        BOOL collapsed = [[sectionDictionary objectForKey:@"collapsed"] boolValue];
        

        if(collapsed)
        {
            [((ZSRoundCell *)cell) setCornerRounding:UIRectCornerAllCorners];
        }
        
        else
        {
            [((ZSRoundCell *)cell) setCornerRounding:(UIRectCornerTopLeft | UIRectCornerTopRight)];
        }
        
    }
    
    else if(indexPath.row == [self.tableView numberOfRowsInSection:indexPath.section] - 1)
    {
        [((ZSRoundCell *)cell) setCornerRounding:(UIRectCornerBottomLeft | UIRectCornerBottomRight)];
    }
    
    else
    {
        [((ZSRoundCell *)cell) setCornerRounding:0];
    }
}


-(void) tableView:(UITableView *)tableView didSelectCellAtChildIndex:(NSInteger)childIndex withInParentCellIndex:(NSInteger)parentIndex
{
    if([[UIMenuController sharedMenuController] isMenuVisible])
    {
        [[UIMenuController sharedMenuController] setMenuVisible:NO];
    }
    
    DkTDocketFile *sectionDictionary = [self.dockets objectAtIndex:parentIndex];
    DkTFile *file = [[sectionDictionary objectForKey:DkTFileDocketFilesKey] objectAtIndex:childIndex];
    ReaderDocument *document = [[ReaderDocument alloc] initWithFilePath:[file objectForKey:DkTFilePathKey] password:nil];
    ReaderViewController *documentViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
    
    DkTDetailViewController *detailViewController = [[DkTDetailViewController alloc] init];
    detailViewController.title = [[[file objectForKey:DkTFilePathKey] lastPathComponent] stringByDeletingPathExtension];
    
    [detailViewController addChildViewController:documentViewController];
    [detailViewController.view addSubview:documentViewController.view];
    [detailViewController setDocketEntry:nil];
    detailViewController.file = file;
    [detailViewController setFilePath:[file objectForKey:DkTFilePathKey]];
    
    UINavigationController *navCtr = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    
    [self presentViewController:navCtr animated:YES completion:^{
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }];

}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[UIMenuController sharedMenuController] isMenuVisible])
    {
        [[UIMenuController sharedMenuController] setMenuVisible:NO];
    }
    
    DkTDocketFile *sectionDictionary = [self.dockets objectAtIndex:indexPath.section];
    
    if(indexPath.row == 0)
    {

        BOOL collapsed = [[sectionDictionary objectForKey:DkTFileDocketCollapsedKey] boolValue];
        
       // NSMutableArray *paths = [NSMutableArray array];
        
        [sectionDictionary setObject:[NSNumber numberWithBool:!collapsed] forKey:DkTFileDocketCollapsedKey];
            
        /*
         NSInteger fileCount = [[sectionDictionary objectForKey:DkTFileDocketFilesKey] count];
            
        for(int i = 1; i <= fileCount; ++i)
        {
            [paths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        }*/
        
        /*
        CGRect frame = self.tableView.frame;
        CGFloat delta = (collapsed*2 - 1) * fileCount * self.tableView.rowHeight;
        frame.size.height += delta;
        frame.size.height = MAX(self.dockets.count*self.tableView.rowHeight, frame.size.height);
        frame.size.height = MIN(self.view.frame.size.height-self.tableView.frame.origin.y-(PAD_OR_POD(100, 60)), frame.size.height);*/
    
       // if(delta <= 0) [CATransaction setCompletionBlock:^{
           // self.tableView.frame = frame;
          //  [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        //}];
        
      //[UIView animateWithDuration:.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
          
         // self.tableView.frame = frame;
          /*
          if(collapsed)
              [tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
          
          else
              [tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
          
          */
        [tableView reloadData];
        [self resizeTableView];
        
          
   //  } completion:^(BOOL finished) {
          
   //   }];
    
        
    }
    
    else
    {
        
        DkTFile *file = [[sectionDictionary objectForKey:DkTFileDocketFilesKey] objectAtIndex:indexPath.row - 1];
        ReaderDocument *document = [[ReaderDocument alloc] initWithFilePath:[file objectForKey:DkTFilePathKey] password:nil];
        ReaderViewController *documentViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
        
        DkTDetailViewController *detailViewController = [[DkTDetailViewController alloc] init];
        detailViewController.title = [[[file objectForKey:DkTFilePathKey] lastPathComponent] stringByDeletingPathExtension];
        
        [detailViewController addChildViewController:documentViewController];
        [detailViewController.view addSubview:documentViewController.view];
        [detailViewController setDocketEntry:nil];
        detailViewController.file = file;
        [detailViewController setFilePath:[file objectForKey:DkTFilePathKey]];
        
        UINavigationController *navCtr = [[UINavigationController alloc] initWithRootViewController:detailViewController];
        
        [self presentViewController:navCtr animated:YES completion:^{
            [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
        }];
    }
}

-(void) didSaveFile:(DkTFile *)file
{
    if(self.isViewLoaded)
    {
        [self.tableView reloadData];
        [self resizeTableView];
        [self.tableView setNeedsDisplay];
    }
}


-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *sectionDictionary = [self.dockets objectAtIndex:indexPath.section];
    NSString *docketName = [sectionDictionary objectForKey:DkTFileDocketNameKey];
    
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        if(indexPath.row == 0)
        {
            [[DkTDocumentManager sharedManager] removeDocketNamed:docketName];
        }
        
        else
        {
            DkTFile *file = [[sectionDictionary objectForKey:DkTFileDocketFilesKey] objectAtIndex:indexPath.row - 1];
            [[DkTDocumentManager sharedManager] removeFile:file];
        }
        
        self.dockets = [[DkTDocumentManager sharedManager] dockets];
        [self.tableView reloadData];
        
        self.noDocumentLabel.hidden = (self.dockets.count > 0);
    }

}

-(void) menuForIndexPath:(NSIndexPath *)indexPath
{
    
    [self.tableView becomeFirstResponder];
    
    PSMenuItem *batch = [[PSMenuItem alloc] initWithTitle:@"Batch Documents" block:^{
        
        [self batchDocuments:indexPath];
        
        
    }];
    
    PSMenuItem *zip = [[PSMenuItem alloc] initWithTitle:@"Zip" block:^{
        [self zipIndexPath:indexPath];
        
    }];
    
    [batch cxa_setImage:[[UIImage imageNamed:@"write"] imageWithColor:[UIColor inactiveColor]] forTitle:@""];
    
    [zip cxa_setImage:[[UIImage imageNamed:@"clip"] imageWithColor:[UIColor inactiveColor]] forTitle:@" "];
    
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    [menu setMenuItems:@[batch, zip]];
    
    //CGFloat width =  self.detailViewController.contentSizeForViewInPopover.width;
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    //rect.size.width = width;
    
    [menu setTargetRect:rect inView:self.tableView];
    [menu setMenuVisible:YES];
}

#pragma mark - Gestures

-(UILongPressGestureRecognizer *) longPress
{
    return [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
}

-(void) handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if(sender.state == UIGestureRecognizerStateBegan)
    {
        UIView *view = [sender view];
        UIView *superview = [view superview];
        
        while (![superview isKindOfClass:[UITableViewCell class]]) {
            superview = [superview superview];
        };
        
        
        UITableViewCell *cell = (UITableViewCell *)superview;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        if(indexPath.row == 0) [self menuForIndexPath:indexPath];
        
        else
        {
            NSMutableDictionary *sectionDictionary = [self.dockets objectAtIndex:indexPath.section];
            DkTFile *file = [[sectionDictionary objectForKey:DkTFileDocketFilesKey] objectAtIndex:indexPath.row-1];
            NSURL *url = [NSURL fileURLWithPath:[file objectForKey:DkTFilePathKey]];
            _doccontroller = [UIDocumentInteractionController interactionControllerWithURL:url];
            _doccontroller.delegate = self;
            if(![_doccontroller presentOpenInMenuFromRect:cell.contentView.frame inView:self.view animated:YES])
            {
                DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"No PDF Application" andMessage:@"You do not have an external application for reading pdfs."];
                [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                    [alertView dismissAnimated:YES];
                }];
                
                [alertView show];
            }
        }
    }
    
}


-(void) viewDidDisappear:(BOOL)animated
{
    [[UIMenuController sharedMenuController] setMenuItems:nil];
    [[DkTDocumentManager sharedManager] sync];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end

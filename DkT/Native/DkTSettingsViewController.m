//
//  RECAPSettingsViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 6/24/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSettingsViewController.h"
#import "DkTSettingsChildViewController.h"
#import "DkTSettingsTableViewController.h"
#import "DkTSidePanelController.h"
#import "DkTAboutViewController.h"
#import "DkTLoginViewController.h"
#import "DkTSearchViewController.h"
#import "DkTUser.h"
#import "FSButton.h"
#import "PACERClient.h"
#import "MBProgressHUD.h"
#import "UIImage+Utilities.h"
#import "DkTSettingsCell.h"
#import "DkTSettings.h"
#import <QuartzCore/QuartzCore.h>
#import "DkTDocumentManager.h"
#import "DkTAlertView.h"
#import "ReaderViewController.h"
#import "ZSHelpController.h"

@interface DkTSettingsViewController ()
{
    bool selected[4];
}
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSArray *descriptions;
@property (nonatomic, strong) NSArray *itemNames;
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation DkTSettingsViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(toggleRecent:)
                                                     name:@"forceLogout"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(toggleRecent:)
                                                     name:@"loginSuccessful"
                                                   object:nil];
        
        [[DkTSettings sharedSettings] setBoolValue:NO forKey:DkTSettingsRECAPEnabledKey];
        
        for(int i = 0; i < 4; ++i)
        {
            selected[i] = NO;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    self.items = @[ [kSettingsImage imageWithColor:[UIColor inactiveColor]],
                    [kSessionButtonImage imageWithColor:[UIColor inactiveColor]],
                    [kInfoImage imageWithColor:[UIColor inactiveColor]],
                    [kQuestionsImage imageWithColor:[UIColor inactiveColor]],
                    ];
    
    self.itemNames = @[ @"Settings",@"Recent",@"About",@"Help"];
    self.descriptions = @[@"Toggle Settings", @"Press to login as a recent user.", @"About DkT", @""];
    self.view.backgroundColor = [UIColor clearColor];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(60,60);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        layout.minimumLineSpacing = 120.0;
        layout.minimumInteritemSpacing = 20.0;
    }
    
    else
    {
        layout.minimumLineSpacing =  20.0f;
        layout.minimumInteritemSpacing = 20.0;
    }
    


    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [self setCollectionViewFrame:self.interfaceOrientation];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.collectionView];
    
    [self.collectionView registerClass:[DkTSettingsCell class] forCellWithReuseIdentifier:@"Cell"];
    
    
    
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
   // if (section == 0)
    
        return UIEdgeInsetsMake(30, 30, (IS_IPHONE5) ? 30 : 5, 30);
                                        
    //else return PAD_OR_POD(UIEdgeInsetsMake(30, 60, 30, 60), UIEdgeInsetsMake(10, 60, 30, 60));
}

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 4;
}

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DkTSettingsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [cell setImage:[self.items objectAtIndex:indexPath.item]];
    cell.label.text = [self.itemNames objectAtIndex:indexPath.item];
    
    
    [cell setInverted:selected[indexPath.item]];
    
    
    if([[self.descriptions objectAtIndex:indexPath.item] length] > 0) cell.contentView.helpText = [self.descriptions objectAtIndex:indexPath.item];
    
    return cell;
}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    selected[indexPath.item] = !selected[indexPath.item];
    DkTSettingsCell *cell = (DkTSettingsCell *)[self collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    [cell setInverted:selected[indexPath.item]];
    
    CGPoint point = [self.view convertPoint:cell.frame.origin fromView:self.collectionView];
    CGRect frame = cell.frame; frame.origin = point; cell.frame = frame;
    DkTSettingsChildViewController *childVC;
    
    
    
    switch (indexPath.item) {
        case 0:
        {
            DkTSettingsCell *c = (DkTSettingsCell *)[self collectionView:collectionView cellForItemAtIndexPath:indexPath];
            c.frame = cell.frame;
            childVC = [[DkTSettingsTableViewController alloc] initWithSettingsCell:c];
            childVC.position = 0;
            childVC.frame = PAD_OR_POD(CGRectMake(10, 20, self.collectionView.frame.size.width, self.collectionView.frame.size.height/1.25), CGRectMake(self.collectionView.frame.origin.x, self.collectionView.frame.origin.y+20, self.collectionView.frame.size.width, self.collectionView.frame.size.height/1.8));
            childVC.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.collectionView.frame.size.width, self.collectionView.frame.size.height);
            [((DkTSidePanelController *)self.parentViewController).containerView addSubview:childVC.view];
            [self.parentViewController addChildViewController:childVC];
            
            
        }
            
            break;
        
        case 1:
        {
            DkTLoginViewController *loginController = ((DkTSidePanelController *)self.parentViewController).loginViewController;
            [loginController toggleUserView:selected[1]];
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:0]]];
        } break;
        case 2:
        {
            
            
            DkTSettingsCell *c = (DkTSettingsCell *)[self collectionView:collectionView cellForItemAtIndexPath:indexPath];
            c.frame = cell.frame;
            childVC = [[DkTAboutViewController alloc] initWithSettingsCell:c];
            childVC.position = 2;
            childVC.frame = PAD_OR_POD(CGRectMake(10, 20, self.collectionView.frame.size.width, self.collectionView.frame.size.height/1.25), CGRectMake(self.collectionView.frame.origin.x, self.collectionView.frame.origin.y+20, self.collectionView.frame.size.width, self.collectionView.frame.size.height/1.8));
            childVC.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.collectionView.frame.size.width, self.collectionView.frame.size.height);
            [((DkTSidePanelController *)self.parentViewController).containerView addSubview:childVC.view];
            [self.parentViewController addChildViewController:childVC];
            
        } break;
        case 3:
        {
            [ZSHelpController toggle];
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:3 inSection:0]]];
            
            if (selected[3])
            {
                DkTAlertView *helpAlert = [[DkTAlertView alloc] initWithTitle:@"Help Activated" andMessage:@"Help mode is now active and dialog bubbles will be displayed. Retap Help to deactivate.\n\nClick on More for the help guide."];
                helpAlert.messageFont = [UIFont fontWithName:kMainFont size:9];
                [helpAlert addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                    [alertView dismissAnimated:YES];
                }];
                
                [helpAlert addButtonWithTitle:@"More" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                    
                    
                    ReaderDocument *document = [[ReaderDocument alloc] initWithFilePath:[DkTDocumentManager helpDocumentPath] password:nil];
                    ReaderViewController *documentViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
                    documentViewController.title = @"Help Guide";
                    
                    
                    documentViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(done)];
                    
                    UINavigationController *nextViewController = [[UINavigationController alloc] initWithRootViewController:documentViewController];
                    nextViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                    nextViewController.modalPresentationStyle = UIModalPresentationFullScreen;
                    UIViewController *parent = [self parentViewController];
                    [parent presentViewController:nextViewController animated:YES completion:^{
                        
                    }];
                    
                    [alertView dismissAnimated:YES];
                }];
                
                [helpAlert show];
            }

            
        }

            break;
        default:
            break;
            
    }
    
    
}

-(void) done
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


-(void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


/*
@implementation DkTSettingsViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        for(int i = 0; i < 4; ++i)
        {
            selected[i] = NO;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    selected[1] = [[[DkTSettings sharedSettings] valueForKey:DkTSettingsRECAPEnabledKey] boolValue];
    self.navigationController.navigationBarHidden = YES;
    
    self.items = @[ [kSessionButtonImage imageWithColor:[UIColor inactiveColor]],
                   [kSettingsImage imageWithColor:[UIColor inactiveColor]],
                   [kInfoImage imageWithColor:[UIColor inactiveColor]],
                   [kQuestionsImage imageWithColor:[UIColor inactiveColor]]];
    
    self.itemNames = @[ @"Recent", @"RECAP", @"About", @"Help"];
    self.descriptions = @[ @"Press to display recent logins for quick logins to PACER.", @"Activate RECAP", @"About DkT", @""];
    self.view.backgroundColor = [UIColor clearColor];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(60,60);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        layout.minimumLineSpacing = 180.0;
        layout.minimumInteritemSpacing = 80.0;
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    else
    {
        layout.minimumLineSpacing = 20.0f;
        layout.minimumInteritemSpacing = 20.0;
        layout.sectionInset = UIEdgeInsetsMake(40, 50, 30, 50);
    }
    
    CGRect frame = CGRectMake(10, 0, 240, 320);

    self.collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.collectionView];
    
    [self.collectionView registerClass:[DkTSettingsCell class] forCellWithReuseIdentifier:@"Cell"];
    
    
    
}

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DkTSettingsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [cell setImage:[self.items objectAtIndex:indexPath.item]];
    cell.label.text = [self.itemNames objectAtIndex:indexPath.item];
    
   
    [cell setInverted:selected[indexPath.item]];
    
    
    if([[self.descriptions objectAtIndex:indexPath.item] length] > 0) cell.contentView.helpText = [self.descriptions objectAtIndex:indexPath.item];
    
    return cell;
}



-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    selected[indexPath.item] = !selected[indexPath.item];
    DkTSettingsCell *cell = (DkTSettingsCell *)[self collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    [cell setInverted:selected[indexPath.item]];
    
    CGPoint point = [self.view convertPoint:cell.frame.origin fromView:self.collectionView];
    CGRect frame = cell.frame; frame.origin = point; cell.frame = frame;
    DkTSettingsChildViewController *childVC;
    

    
    switch (indexPath.item) {
        case 0:
        {
            DkTLoginViewController *loginController = ((DkTSidePanelController *)self.parentViewController).loginViewController;
            [loginController toggleUserView:selected[0]];
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
            
        }
            
            break;
        case 1:
        {
            BOOL settings = [[[DkTSettings sharedSettings] valueForKey:DkTSettingsRECAPEnabledKey] boolValue];
            [[DkTSettings sharedSettings] setBoolValue:!settings forKey:DkTSettingsRECAPEnabledKey];
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:0]]];
           
            if (selected[1])
            {
                id value = [[DkTSettings sharedSettings] valueForKey:DkTSettingsRECAPWarningKey];
                if((value == nil) || [value boolValue] == FALSE)
                {
                    DkTAlertView *recapAlert = [[DkTAlertView alloc] initWithTitle:@"RECAP Enabled" andMessage:@"You will now have the option to download PACER documents from the public archive for free and will automatically upload dockets and documents to the archive.  Using RECAP on PACER accounts with fee exemptions may violate the terms of exemption."];
                    recapAlert.messageFont = [UIFont fontWithName:kMainFont size:9];
                    recapAlert.buttonFont =[UIFont fontWithName:kMainFont size:8];
                    [recapAlert addButtonWithTitle:@"Don't warn again." type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                        [alertView dismissAnimated:YES];
                        [[DkTSettings sharedSettings] setBoolValue:TRUE forKey:DkTSettingsRECAPWarningKey];
                    }];
                    
                    [recapAlert addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                        [alertView dismissAnimated:YES];
                        [[DkTSettings sharedSettings] setBoolValue:FALSE forKey:DkTSettingsRECAPWarningKey];
                    }];
                    
                    [recapAlert show];
                }

            }
            
            
            
        } break;
        case 2:
        {
            
            DkTSettingsCell *c = (DkTSettingsCell *)[self collectionView:collectionView cellForItemAtIndexPath:indexPath];
            c.frame = cell.frame;
            childVC = [[DkTAboutViewController alloc] initWithSettingsCell:c];
            childVC.position = 2;
            childVC.frame = PAD_OR_POD(self.collectionView.frame, CGRectMake(self.collectionView.frame.origin.x, self.collectionView.frame.origin.y+20, self.collectionView.frame.size.width, self.collectionView.frame.size.height/1.8));
            childVC.view.frame = self.view.frame;
            
            [((DkTSidePanelController *)self.parentViewController).containerView addSubview:childVC.view];
            [self.parentViewController addChildViewController:childVC];
        }
            break;
        case 3:
        {
            [ZSHelpController toggle];
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:3 inSection:0]]];
            
            if (selected[3])
            {
                DkTAlertView *helpAlert = [[DkTAlertView alloc] initWithTitle:@"Help Activated" andMessage:@"Help is now active. Touch on an area for a help description. Retap Help to deactivate.\n\nClick on More to view a detailed help document."];
                helpAlert.messageFont = [UIFont fontWithName:kMainFont size:9];
                [helpAlert addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                    [alertView dismissAnimated:YES];
                }];
                
                [helpAlert addButtonWithTitle:@"More" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                    
                    
                    ReaderDocument *document = [[ReaderDocument alloc] initWithFilePath:[DkTDocumentManager helpDocumentPath] password:nil];
                    ReaderViewController *documentViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
                    documentViewController.title = @"Help Guide";
                    
                    documentViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(done)];
                    
                    UINavigationController *nextViewController = [[UINavigationController alloc] initWithRootViewController:documentViewController];
                    nextViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                    nextViewController.modalPresentationStyle = UIModalPresentationFullScreen;
                    UIViewController *parent = [self parentViewController];
                    [parent presentViewController:nextViewController animated:YES completion:^{
                        
                    }];
                    
                    [alertView dismissAnimated:YES];
                }];
                
                [helpAlert show];
            }

        }
            break;
            default:
            break;
    
    }
        
    
}

-(void) done
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

-(void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
 */

-(void) willRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        
    {
        
        if(UIInterfaceOrientationIsPortrait(fromInterfaceOrientation))[self setCollectionViewFrame:UIInterfaceOrientationLandscapeRight | UIInterfaceOrientationLandscapeLeft];
        
        else [self setCollectionViewFrame:UIInterfaceOrientationPortrait];
        
    }
}

-(void) setCollectionViewFrame:(UIInterfaceOrientation)currentOrientation
{
    CGFloat y = UIInterfaceOrientationIsPortrait(currentOrientation) || (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 0 : 20;
    self.collectionView.frame = CGRectMake(10, y, 240, PAD_OR_POD(400,300));
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) toggleRecent:(id)sender
{
    if(selected[1]) [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
}

@end


//
//  RECAPSettingsViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 6/24/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSettingsViewController.h"
#import "DkTSettingsChildViewController.h"
#import "DkTSidePanelController.h"
#import "DkTLoginViewController.h"
#import "DkTSearchViewController.h"
#import "DkTUser.h"
#import "FSButton.h"
#import "PACERClient.h"
#import "MBProgressHUD.h"
#import "UIImage+Utilities.h"
#import "DkTSettingsCell.h"
#import <QuartzCore/QuartzCore.h>
#import <StoreKit/StoreKit.h>
#import "ZSHelpController.h"

@interface DkTSettingsViewController ()
{
    NSInteger _selectedIndex;
}
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSArray *itemNames;
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation DkTSettingsViewController

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
    
    self.navigationController.navigationBarHidden = YES;
    
    self.items = @[ [kSettingsImage imageWithColor:kInactiveColor],
                   [kQuestionsImage imageWithColor:kInactiveColor],
                   [kInfoImage imageWithColor:kInactiveColor],
                   [kShareIcon imageWithColor:kInactiveColor]];
    
    self.itemNames = @[ @"Settings", @"Help", @"About", @"Share"];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(60,60);
    layout.minimumInteritemSpacing = 80.0;
    layout.minimumLineSpacing = 180.0;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
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
    cell.helpText = @"Test";
    
    if(indexPath.item == _selectedIndex)
    {
        [cell invert];
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    DkTSettingsCell *cell = (DkTSettingsCell *)[self collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
    
    CGPoint point = [self.view convertPoint:cell.frame.origin fromView:self.collectionView];
    CGRect frame = cell.frame; frame.origin = point; cell.frame = frame;
    DkTSettingsChildViewController *childVC;
    
    switch (indexPath.item) {
        case 0:
        {
            childVC = [[DkTSettingsTableViewController alloc] initWithSettingsCell:cell];
            childVC.position = indexPath.item;
            childVC.frame = self.collectionView.frame;
            childVC.view.frame = self.view.frame;
            
            [((DkTSidePanelController *)self.parentViewController).containerView addSubview:childVC.view];
            [self.parentViewController addChildViewController:childVC];
        }
            
            break;
        case 1:
        {
            if(_selectedIndex != 1) _selectedIndex = 1;
            
            else _selectedIndex = NSNotFound;
            
            [ZSHelpController toggle];
            
            [UIView setAnimationsEnabled:NO];
            
            [collectionView performBatchUpdates:^{
               [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:0]]];
            } completion:^(BOOL finished) {
                [UIView setAnimationsEnabled:YES];
            }];
            
            
        }
        case 3:
        {
            SKStoreProductViewController *storeProductViewController = [[SKStoreProductViewController alloc] init];
            // Configure View Controller
            [storeProductViewController setDelegate:self];
            [storeProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier : kAppID} completionBlock:^(BOOL result, NSError *error) {
                if (error) {
                    NSLog(@"Error %@ with User Info %@.", error, [error userInfo]);
                } else {
                    // Present Store Product View Controller
                    [self presentViewController:storeProductViewController animated:YES completion:nil];
                }
            }];
        } break; 
        default:
        {
            childVC = [[DkTSettingsChildViewController alloc] initWithSettingsCell:cell];
            childVC.position = 1;
        }
            break;
    
    }
    
    
    
    
}
-(void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end


//
//  DkTRecentDocketViewController.m
//  DkT
//
//  Created by Matthew Zorn on 3/23/14.
//  Copyright (c) 2014 Matthew Zorn. All rights reserved.
//

#import "DkTRecentDocketViewController.h"
#import "DkTRecentDocketManager.h"
#import "DkTDocketViewController.h"
#import "DkTCodeManager.h"
#import "PSMenuItem.h"
#import "MBProgressHUD.h"
#import "PACERClient.h"
#import "DkTAlertView.h"
#import "ZSRoundCell.h"

@interface DkTRecentDocketViewController ()
@end

@implementation DkTRecentDocketViewController

- (id)init {
    if(self = [super init]) {
    }
    return self;
}

-(void) initialize {
    self.bookmarkManager = [DkTRecentDocketManager sharedManager];
    self.bookmarks = [[self.bookmarkManager bookmarks] mutableCopy];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	CGRect frame = self.tableView.frame;
    frame.origin.y+=20;
    self.tableView.frame = frame;
}

-(void) setup
{
    [super setup];
    self.noDocumentLabel.text = @"No recently viewed dockets.";
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZSRoundCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    
    CGFloat unit = self.tableView.rowHeight*.9;
    
    //switch the style
    if(cell == nil)
    {
        cell = [[ZSRoundCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont fontWithName:kLightFont size:PAD_OR_POD(14, 13)];
        cell.textLabel.adjustsFontSizeToFitWidth = NO;
        cell.textLabel.numberOfLines = 1;
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor darkerTextColor];
        cell.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        cell.detailTextLabel.font = [UIFont fontWithName:kContrastFont size:9];
        cell.detailTextLabel.textColor = [UIColor darkerTextColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.numberOfLines = 2;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor inactiveColor];
        cell.accessoryView.backgroundColor = [UIColor clearColor];
        cell.badgeTextColor = [UIColor inactiveColor];
        cell.badgeColor = [UIColor activeColor];
        cell.badgeRightOffset = PAD_OR_POD(unit*3+5, 5);
        
        cell.contentView.helpText = @"Click to view a recently viewed docket. Will incur PACER charge.";
        
    }
    
    
    if(indexPath.row == 0)
    {
        cell.cornerRadius = 5.0f;
        cell.cornerRounding = UIRectCornerTopLeft | UIRectCornerTopRight;
    }
    
    else if(indexPath.row == self.bookmarks.count)
    {
        cell.cornerRadius = 5.0f;
        cell.cornerRounding = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    }
    
    cell.contentView.backgroundColor = (indexPath.row%2 == 0) ? [UIColor inactiveColor] : [UIColor inactiveColorDark];
    cell.backgroundView = [[UIView alloc] init];
    cell.backgroundView.backgroundColor = cell.contentView.backgroundColor;
    
    
    DkTDocket *item = [self.bookmarks objectAtIndex:indexPath.row];
    NSString *path = [self.bookmarkManager bookmarkPath:item];
    
        
    cell.textLabel.text = item.name;
    NSString *subtitle = [NSString stringWithFormat:@"%@, %@", item.case_num, [DkTCodeManager translateCode:[item court]  inputFormat:DkTCodePACERDisplayKey outputFormat:DkTCodeBluebookKey]];
    NSString *datestring = [NSString stringWithFormat:PAD_OR_POD(@"  (visited %@)", @"\nVisited %@") , item.updated];
    subtitle = [subtitle stringByAppendingString:datestring];

    cell.detailTextLabel.text = subtitle;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        cell.imageView.image = [[DkTImageCache sharedCache] imageNamed:@"bookmark" color:[UIColor activeColor]];
        cell.imageView.transform = CGAffineTransformMakeScale(.5, .5);
    }
    
    return cell;
}

-(BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DkTDocket *docket = [self.bookmarks objectAtIndex:indexPath.row];
    NSString *path = [self.bookmarkManager bookmarkPath:docket];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [self showSavedDocket:docket];
    }
    
    else {
        
        if(docket.link.length > 0 && [self connectivityStatus])
        {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.color = [UIColor clearColor];
            
            [[PACERClient sharedClient] retrieveDocket:docket sender:self];
        }
    }
}

-(void) showSavedDocket:(DkTDocket *)docket
{
    NSArray *entries = [[DkTBookmarkManager sharedManager] savedDocket:docket];
    [super handleSavedDocket:docket entries:entries];
}

-(void) handleDocumentsFromDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry entries:(NSArray *)entries {
    
}

-(void) handleDocket:(DkTDocket *)docket entries:(NSArray *)entries to:(NSString *)to from:(NSString *)from
{
    UIViewController *parent = [self parentViewController];
    
    if(parent.presentedViewController == nil)
    {
        if(entries.count > 0)
        {
            DkTDocketViewController *nextViewController = [[DkTDocketViewController alloc] initWithDocket:docket];
            nextViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            nextViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            UIViewController *parent = [self parentViewController];
            
            nextViewController.masterViewController.docketEntries = entries;
            [nextViewController.masterViewController.tableView reloadData];
            
            [parent presentViewController:nextViewController animated:YES completion:^{
                
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                
                [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
            }];
        }
        
        else
        {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Error" andMessage:@"Error parsing docket."];
            [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                [alertView dismissAnimated:YES];
            }];
            [alertView show];
        }
        
    }
    
}

-(void) handleDocketError:(DkTDocket *)docket
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    if(self.presentedViewController == nil)
    {
        DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Search" andMessage:@"Error loading docket."];
        
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            
            [alertView dismissAnimated:YES];
            
        }];
        
        [alertView show];
    }
}

@end

//
//  RECAPSearchResultsViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/27/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSearchResultsViewController.h"
#import "DkTBookmarkManager.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Utilities.h"
#import "DkTConstants.h"
#import "DkTDocket.h"
#import "PACERClient.h"
#import "PACERParser.h"
#import "MBProgressHUD.h"
#import "FSButton.h"
#import "DkTDocketViewController.h"
#import "UIResponder+FirstResponder.h"

@interface DkTSearchResultsViewController ()

@end

@implementation DkTSearchResultsViewController

- (id)init{
    
    self = [super init];
    if (self) {
        [self.navigationController setNavigationBarHidden:YES];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = kActiveColor;
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.backButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.results.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [[[self.results objectAtIndex:section] objectForKey:@"items"] count];
    return count;
}
-(UITableView *) tableView
{
    if(_tableView == nil)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        
        _tableView.rowHeight = 60;
        
        CGRect frame;
        frame.size.height = _tableView.rowHeight * MIN([self rowCount],10) + self.results.count * self.tableView.sectionHeaderHeight;
        frame.size.width = self.view.frame.size.width*.85;
        frame.origin = CGPointMake((self.view.frame.size.width -frame.size.width)/2.0,(self.view.frame.size.width -frame.size.width*1.1));
        _tableView.frame = frame;
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.scrollEnabled = YES;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorColor = kActiveColor;
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = kActiveColor;
        [_tableView setBackgroundView:backgroundView];
        _tableView.clipsToBounds = YES;
        _tableView.layer.cornerRadius = 5.0;
        
    }
    
    return _tableView;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *items = [[self.results objectAtIndex:indexPath.section] objectForKey:@"items"];
    DkTDocket *docket = [items objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont fontWithName:kLightFont size:16];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = kDarkTextColor;
        cell.detailTextLabel.font = [UIFont fontWithName:kContrastFont size:12];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(bookmarkDocket:)];
        gestureRecognizer.minimumPressDuration = 1.0;
        [cell addGestureRecognizer:gestureRecognizer];
        
        
    }
    
    if( (indexPath.section == self.results.count - 1) && (indexPath.row == items.count - 1))
    {
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:cell.bounds
                                                       byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight)
                                                             cornerRadii:CGSizeMake(5.0, 5.0)];
       
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = cell.contentView.bounds;
        maskLayer.path = maskPath.CGPath;
        cell.layer.mask = maskLayer;
    }
    
    if( (indexPath.section == 0) && (indexPath.row == 0) && (self.results.count == 1))
    {
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:cell.contentView.bounds
                                                       byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                                             cornerRadii:CGSizeMake(5.0, 5.0)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = cell.bounds;
        maskLayer.path = maskPath.CGPath;
        cell.contentView.layer.mask = maskLayer;
    }
    
    
    
    cell.contentView.backgroundColor = (indexPath.row%2 == 0) ? kInactiveColor : kInactiveColorDark;
    
    cell.imageView.image = [kDocketImage imageWithColor:kActiveColor];
    cell.imageView.transform = CGAffineTransformMakeScale(.5, .5);
    cell.textLabel.text = docket.name;
    cell.detailTextLabel.text = docket.court;
    
    cell.detailTextLabel.textColor = (indexPath.row%2 == 0) ? kActiveColor : kInactiveColor;
    return cell;
}


- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [[self.results objectAtIndex:section] objectForKey:@"name"];
    
    if(title.length > 1)
    {
        UILabel *headerView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
        headerView.backgroundColor = kActiveColor;
        headerView.text = [[self.results objectAtIndex:section] objectForKey:@"name"];
        
        return headerView;
    }
    
    else return [[UIView alloc] initWithFrame:CGRectZero];
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return (self.results.count > 1) ? 30 : 0.0;
}

-(NSInteger) rowCount
{
    int sum = 0;
    
    for(NSDictionary *dict in self.results) sum += [[dict objectForKey:@"items"] count];
    
    return sum;
}

-(void) postSearchResults:(NSArray *)results nextPage:(NSString *)nextPage
{
    
    self.nextPage = nextPage;
    
    for(int i = 0; i < results.count; ++i)
    {
        
        NSDictionary *dict = [results objectAtIndex:i];
        NSString *name = [dict objectForKey:@"name"];
        NSArray *searchItems = [dict objectForKey:@"items"];
        NSMutableArray *items;
        
        
        
        if([[self.results valueForKey:@"name"] containsObject:name])
        {
            for(NSDictionary *dict in self.results)
            {
                if([[dict objectForKey:@"name"] isEqualToString:name])
                {
                    items = [dict objectForKey:@"items"];
                    [items addObjectsFromArray:searchItems];
                }
            }
            
        }
        
        else
        {
            items = [[NSMutableArray alloc] initWithArray:searchItems];
            NSDictionary *section = @{name:items};
            
            [self.results addObject:section];
        }
    }
    
    [self.tableView reloadData];
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *items = [[self.results objectAtIndex:indexPath.section] objectForKey:@"items"];
    
    DkTDocket *selectedDocket = [items objectAtIndex:indexPath.row];
    
    if(selectedDocket.link.length > 0)
    {
        UIResponder *firstResponder = [UIResponder currentFirstResponder];
        [firstResponder resignFirstResponder];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.color = kActiveColor;
        
        [[PACERClient sharedClient] getDocket:selectedDocket sender:self];
    }
}

-(void) handleDocket:(DkTDocket *)docket entries:(NSArray *)entries
{
    DkTDocketViewController *nextViewController = [[DkTDocketViewController alloc] initWithDocket:docket];
    nextViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    nextViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    UIViewController *parent = [self parentViewController];
    
    nextViewController.masterViewController.docketEntries = entries;
    [nextViewController.masterViewController.tableView reloadData];
    [parent presentViewController:nextViewController animated:YES completion:^{
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
    
}

-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.bounds;
    CGSize size = scrollView.contentSize;
    UIEdgeInsets edgeInsets = scrollView.contentInset;
    
    float y = offset.y+bounds.size.height - edgeInsets.bottom;
    float h = size.height;
    
    float threshold = 10;
    
    if((self.nextPage.length > 0) && (y > h + threshold))
    {
        [self loadNextPage];
    }
}

-(void) loadNextPage
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.color = kActiveColor;
    
    [[PACERClient sharedClient] getPath:self.nextPage parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSMutableArray *array = [PACERParser parseSearchResults:responseObject];
        NSString *nextPage = [PACERParser parseForNextPage:responseObject];
        
        [self postSearchResults:array nextPage:nextPage];
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        self.nextPage = @"";
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
    
}

-(UIButton *) backButton
{
    if(_backButton == nil)
    {
        NSArray *colors = @[kInactiveColor, kDarkTextColor];
        _backButton = [FSButton buttonWithIcon:nil colors:colors title:@"Back" actionBlock:^{
            [self.navigationController popToRootViewControllerAnimated:YES];
        }];
        
        _backButton.titleLabel.font = [UIFont fontWithName:kMainFont size:16];
        
        CGRect frame;
        frame.size.width = self.tableView.rowHeight*2.5;
        frame.size.height = self.tableView.rowHeight*.75;
        frame.origin = CGPointMake((self.tableView.center.x-frame.size.width)/2.0, CGRectGetMaxY(self.tableView.frame)+self.tableView.frame.origin.y);
        _backButton.frame = frame;
        
        _backButton.layer.cornerRadius = 5.0;
    }
    
    return _backButton;
}


-(void) bookmarkDocket:(UIGestureRecognizer *)sender
{
    UITableViewCell *cell = (UITableViewCell *)[[sender view] superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    NSArray *items = [[self.results objectAtIndex:indexPath.section] objectForKey:@"items"];
    DkTDocket *docket = [items objectAtIndex:indexPath.row];
    
    [[DkTBookmarkManager sharedManager] addBookmark:docket];
    
}
@end

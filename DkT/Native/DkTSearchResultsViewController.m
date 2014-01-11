
//
//  Created by Matthew Zorn on 5/27/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>

#import "DkTSingleton.h"
#import "DkTSearchResultsViewController.h"
#import "DkTDocketTableViewController.h"
#import "UIImage+Utilities.h"
#import "DkTDocket.h"
#import "PACERClient.h"
#import "PACERParser.h"
#import "MBProgressHUD.h"
#import "FSButton.h"
#import "DkTDocketViewController.h"
#import "UIResponder+FirstResponder.h"
#import "DkTAlertView.h"
#import "PKRevealController.h"
#import "ZSRoundCell.h"
#import "DkTImageCache.h"

@interface DkTSearchResultsViewController ()

@property (nonatomic, strong) NSArray *codes;
@property (nonatomic) BOOL loading;

@end

@implementation DkTSearchResultsViewController

- (id)init{
    
    self = [super init];
    if (self) {
        [self.navigationController setNavigationBarHidden:YES];
        self.loading = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor activeColor];
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

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section != 0) return 10.0f;
    
    else return 0.0f;
        
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
        IOS7(_tableView.separatorInset = UIEdgeInsetsZero;,);
        _tableView.rowHeight = PAD_OR_POD(65, 52);
        CGRect frame;
        frame.size.height = self.view.frame.size.height * (PAD_OR_POD(.7, .6)) + self.results.count * self.tableView.sectionHeaderHeight;
        frame.size.width = self.view.frame.size.width*.85;
        frame.origin = CGPointMake((self.view.frame.size.width -frame.size.width)/2.0,(self.view.frame.size.width -frame.size.width*1.1));
        _tableView.frame = frame;
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.scrollEnabled = YES;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorColor = [UIColor activeColor];
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor activeColor];
        [_tableView setBackgroundView:backgroundView];
        _tableView.clipsToBounds = YES;
        
        _tableView.layer.cornerRadius = 5.0;
        IOS7(_tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);,  );
    }
    
    return _tableView;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *items = [[self.results objectAtIndex:indexPath.section] objectForKey:@"items"];
    DkTDocket *docket = [items objectAtIndex:indexPath.row];
    
    ZSRoundCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(cell == nil)
    {
        cell = [[ZSRoundCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        
        
        cell.textLabel.font = [UIFont fontWithName:kLightFont size:16];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor darkerTextColor];
        cell.detailTextLabel.font = [UIFont fontWithName:kContrastFont size:12];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        //UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(bookmarkDocket:)];
        //gestureRecognizer.minimumPressDuration = 1.0;
        //[cell addGestureRecognizer:gestureRecognizer];
        
        
    }
    
    cell.contentView.backgroundColor = (indexPath.row%2 == 0) ? [UIColor inactiveColor] : [UIColor inactiveColorDark];
    
    cell.imageView.image = [[DkTImageCache sharedCache] imageNamed:@"docket" color:[UIColor activeColor]];
    cell.imageView.transform = CGAffineTransformMakeScale(.5, .5);
    cell.imageView.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = docket.name;
    
    NSString *subtitle = [NSString stringWithFormat:@"%@, %@", docket.case_num, [DkTCodeManager translateCode:[docket court]  inputFormat:DkTCodePACERDisplayKey outputFormat:DkTCodeBluebookKey]];
    cell.detailTextLabel.text = subtitle;
    cell.detailTextLabel.minimumScaleFactor = .7;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    
    cell.detailTextLabel.textColor = (indexPath.row%2 == 0) ? [UIColor activeColor] : [UIColor inactiveColor];
    return cell;
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZSRoundCell *roundCell = (ZSRoundCell *)cell;
    UIRectCorner corner = 0;
    CGFloat cornerRadius = 0;
    
    
    if(indexPath.row == 0)
    {
        corner = UIRectCornerTopLeft | UIRectCornerTopRight;
        cornerRadius = 5.0f;
    }
    
    if(indexPath.row == [self tableView:self.tableView numberOfRowsInSection:indexPath.section]-1)
    {
        corner = corner | UIRectCornerBottomLeft | UIRectCornerBottomRight;
        cornerRadius = 5.0f;
    }
    
    [roundCell setCornerRadius:cornerRadius];
    [roundCell setCornerRounding:corner];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [[self.results objectAtIndex:section] objectForKey:@"name"];
    
    if(title.length > 1)
    {
        UILabel *headerView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
        headerView.backgroundColor = [UIColor activeColor];
        headerView.text = [[self.results objectAtIndex:section] objectForKey:@"name"];
        headerView.textColor = [UIColor darkerTextColor];
        return headerView;
    }
    
    else return [[UIView alloc] initWithFrame:CGRectZero];
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
            for(NSDictionary *d in self.results)
            {
                if([[dict objectForKey:@"name"] isEqualToString:name])
                {
                    items = [d objectForKey:@"items"];
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
    
    self.loading = NO;
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
        hud.color = [UIColor clearColor];
        
        [[PACERClient sharedClient] retrieveDocket:selectedDocket sender:self];
    }
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

-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(!self.loading)
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
            self.loading = YES;
        }
    }
    
}

-(void) loadNextPage
{
    if(![self connectivityStatus]) return;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.color = [UIColor clearColor];
    
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
        NSArray *colors = @[[UIColor inactiveColor], [UIColor darkerTextColor]];
        _backButton = [FSButton buttonWithIcon:[UIImage imageNamed:@"backarrow"] colors:colors title:@" Back" actionBlock:^{
            [self.navigationController popToRootViewControllerAnimated:YES];
        }];
        
        _backButton.titleLabel.font = [UIFont fontWithName:kMainFont size:16];
        
        CGRect frame;
        frame.size.width = self.tableView.rowHeight*2.5;
        frame.size.height = self.tableView.rowHeight*.75;
        frame.origin = CGPointMake(self.tableView.center.x-frame.size.width/2., CGRectGetMaxY(self.tableView.frame)+self.tableView.frame.origin.y);
        _backButton.frame = frame;
        [_backButton setIconSpacing:15.];
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

-(BOOL) connectivityStatus
{
    PACERConnectivityStatus status = [PACERClient connectivityStatus];
    
    if( (status & PACERConnectivityStatusNoInternet) > 0)
    {
        DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Network Error" andMessage:@"Check Network Connection"];
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            [alertView dismissAnimated:YES];
        }];
        
        [alertView show];
        
        return FALSE;
    }
    
    else if( (status & PACERConnectivityStatusNotLoggedIn) > 0)
    {
        DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Error" andMessage:@"Have you logged into PACER?"];
        
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            
            [alertView dismissAnimated:YES];
            
            [self.parentViewController.revealController showViewController:self.parentViewController.revealController.leftViewController animated:YES completion:^(BOOL finished) {
                
            }];
            
        }];
        
        
        [alertView show];
        return FALSE;
    }
    
    return TRUE;
    
}

@end

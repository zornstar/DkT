//
//  RECAPSearchViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSearchViewController.h"
#import "DkTLoginViewController.h"

#import "DkTSearchResultsViewController.h"

#import "FSPopoverTableViewController.h"
#import "FSButton.h"

#import "RECAPClient.h"
#import "PACERClient.h"

#import "ZUtils.h"

#import "MBProgressHUD.h"
#import "CKCalendarView.h"

#import <QuartzCore/QuartzCore.h>

@interface DkTSearchViewController ()
{
    NSArray *_courtTypes;
    NSArray *_districts;
    NSArray *_bankruptcies;
    NSArray *_appellates;
    NSArray *_states;
    
    NSMutableArray *_keys;
    NSMutableDictionary *_params;
    
    
    PACERRegionType _selectedRegion;
    PACERCourtType _selectedCourtType;
    NSDateFormatter *_dateFormatter;
    NSInteger _selectedIndex;
    NSInteger _activeControl;
    BOOL _keyboardActive;
    
    bool showing[6];
}

@property (nonatomic, strong) NSArray *helpTexts;

@end

@implementation DkTSearchViewController

- (id)init
{
    self = [super init];
    if (self) {
        _loggedIn = NO;
        self.contentSizeForViewInPopover = CGSizeMake(400, 400);
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow) name:UIKeyboardDidShowNotification object:nil];
            _keyboardActive = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = kActiveColor;
    [self setup];
}

-(UITableView *) tableView
{
    if(_tableView == nil)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
     
        _tableView.rowHeight = 60;
        
        CGRect frame;
        frame.size.height = _tableView.rowHeight * self.labels.count;
        frame.size.width = self.view.frame.size.width*.85;
        frame.origin = CGPointMake((self.view.frame.size.width -frame.size.width)/2.0,(self.view.frame.size.width -frame.size.width*1.1));
        _tableView.frame = frame;
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.scrollEnabled = NO;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorColor = kActiveColor;
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = kActiveColor;
        [_tableView setBackgroundView:backgroundView];
        
        _tableView.layer.cornerRadius = 0.0;
    }
    
    return _tableView;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.labels.count;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont fontWithName:kMainFont size:16];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = kDarkTextColor;
        cell.contentView.backgroundColor = kInactiveColor;
        cell.detailTextLabel.textColor = kActiveColor;
        cell.detailTextLabel.font = [UIFont fontWithName:kContrastFont size:16];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.layer.borderColor = kActiveColor.CGColor;
        cell.contentView.layer.borderWidth = 2.0f;
        cell.contentView.layer.cornerRadius = 5.0f;
        cell.backgroundColor = kActiveColor;
        cell.clipsToBounds = YES;
    }
    
    cell.textLabel.text = [self.labels objectAtIndex:indexPath.row];
    id value = [self.data objectAtIndex:indexPath.row];
    
    
    if( (indexPath.row == 0) || (indexPath.row == 1) )
    {
        cell.detailTextLabel.text = (value == [NSNull null]) ? @"" : value;
    }
        
    else if( (indexPath.row == 3) || (indexPath.row == 4) )
    {
        cell.detailTextLabel.text = (value == [NSNull null]) ? @"" : [_dateFormatter stringFromDate:value];
    }
    
    else
    {
        UITextField *textField = [self.controls objectAtIndex:indexPath.row];
        [cell.contentView addSubview:textField];
    }

    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedIndex = indexPath.row;

    if( (indexPath.row == 2) || (indexPath.row == 5)) return;
    
    [self showPickerForIndexPath:indexPath];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) showPickerForIndexPath:(NSIndexPath *)indexPath
{
    showing[indexPath.row] = TRUE;
    
    if( (indexPath.row == 0) || (indexPath.row == 1) )
    {
        FSPopoverTableViewController *popover = [self.controls objectAtIndex:indexPath.row];
        
        [popover present];
    }
    
    if( (indexPath.row == 3) || (indexPath.row == 4) )
    {
        
        CKCalendarView *calendar = [self.controls objectAtIndex:indexPath.row];
        [self.view addSubview:calendar];
    }
    
}


-(void) setup
{
    _courtTypes            = @[@"Appellate",
                             @"Bankruptcy",
                             @"Civil",
                             @"Criminal",
                             @"Multi-District"];
    
    
    
    _appellates            = @[@"First Circuit",
                               @"Second Circuit",
                               @"Third Circuit",
                               @"Fourth Circuit",
                               @"Fifth Circuit",
                               @"Sixth Circuit",
                               @"Seventh Circuit",
                               @"Eighth Circuit",
                               @"Ninth Circuit",
                               @"Tenth Circuit",
                               @"Eleventh Circuit",
                               @"Federal Circuit",
                               @"D.C. Circuit"];
    
   _districts              = @[@"Alabama M.D.",
                               @"Alabama N.D.",
                               @"Alabama S.D.",
                               @"Arkansas E.D."
                               @"Arkansas W.D.",
                               @"California C.D.",
                               @"California E.D.",
                               @"California N.D.",
                               @"California S.D.",
                               @"Florida N.D.",
                               @"Florida M.D.",
                               @"Florida S.D.",
                               @"Georgia N.D.",
                               @"Georgia"];
                                 
    _states                = @[@"Alabama",
                               @"Alaska",
                               @"Arizona",
                               @"Arkansas",
                               @"California",
                               @"Colorado",
                               @"Connecticut",
                               @"Delaware",
                               @"Florida",
                               @"Georgia",
                               @"Hawaii",
                               @"Illinois",
                               @"Indiana",
                               @"Iowa",
                               @"Kansas",
                               @"Kentucky",
                               @"Louisiana",
                               @"Maine",
                               @"Maryland",
                               @"Missouri",
                               @"Montana",
                               @"Nebraska",
                               @"Nevada",
                               @"New Hampshire",
                               @"New Jersey",
                               @"New Mexico",
                               @"New York",
                               @"North Carolina",
                               @"North Dakota",
                               @"Northern Mariana Islands",
                               @"Ohio",
                               @"Oklahoma",
                               @"Oregon",
                               @"Pennsylvania",
                               @"Puerto Rico",
                               @"Rhode Island",
                               @"South Carolina",
                               @"South Dakota",
                               @"Tennessee",
                               @"Texas",
                               @"Utah",
                               @"Vermont",
                               @"Virgin Islands",
                               @"Virginia",
                               @"Washington",
                               @"West Virginia",
                               @"Wisconsin",
                               @"Wyoming"];
    
    _bankruptcies          = @[@"Alabama M.D. Bankruptcy",
                               @"Alabama N.D. Bankruptcy",
                               @"Alabama S.D. Bankruptcy"];
    
    _labels = @[@"Case Type", @"Region", @"Case Number", @"Date Filed", @"Date Closed", @"Party Name"];
    
    _data = [NSMutableArray array];
    
    for (NSInteger i = 0; i < _labels.count; ++i)
    {
        [_data addObject:[NSNull null]];
        showing[i] = FALSE;
    }
    
    self.tableView = [self tableView];
    self.controls = [self controls];
    
    
    [self configureTableViewForCourtTypeSelection:0];
    
    _params = [@{kCourtTypeKey : @"",
                kCaseNoKey : @"",
                kDateFiledStartKey : @"",
                kDateTermStartKey : @"",
                kPartyKey : @""} mutableCopy];

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.searchPACERButton];
}

-(NSDictionary *) pacerParameters
{

    for(int i = 0; i < 8; ++i)
    {
        NSString *str = [self valueForRow:i];
        
        
            switch (i) {
                case 0: {
                    [_params setObject:@"all" forKey:kCourtTypeKey];
                } break;
                case 1: {
                    
                    NSString *key;
                    
                    switch (_selectedCourtType) {
                        case PACERCourtTypeNone: {
                            key = @"all_region";
                        } break;
                        case PACERRegionTypeAppellate: {
                            key = @"ap_region";
                        } break;
                        case PACERCourtTypeBankruptcy: {
                            key = @"bk_region";
                        } break;
                        case PACERCourtTypeCivil: {
                            key = @"dc_region";
                        } break;
                        case PACERCourtTypeCriminal: {
                            key = @"dc_region";
                        } break;
                        case PACERCourtTypeMDL: {
                            key = @"dc_region";
                        } break;
                        default: {
                            key = @"all_region";
                        } break;
                            break;
                    }
                    
                   // [_params setObject:[_regionDictionary objectForKey:str] forKey:key];
                    
                }
                    
                    break;
                case 2:
                    [_params setObject:str forKey:kCaseNoKey];
                default:
                    break;
            }
        
        
    }
    
    return [NSDictionary dictionaryWithDictionary:_params];
}

-(NSString *) valueForRow:(NSInteger)i
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
    
    if(i == 2 || i == 5)
    {
        NSString *str = [[(UITextField *)[self.controls objectAtIndex:i] text] copy];
        return str;
    }
    
    else if (cell.detailTextLabel.text.length > 1) return [cell.detailTextLabel.text copy];
    
    return @"";
}


-(FSButton *) searchPACERButton
{
    if(_searchPACERButton == nil)
    {
        NSArray *colors = @[kInactiveColor, kDarkTextColor];
        _searchPACERButton = [FSButton buttonWithIcon:kSearchSmallImage colors:colors title:@"Search PACER"  actionBlock:^{
            
            NSDictionary *params = [self pacerParameters];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"Searching...";
            hud.color = kInactiveColorDark;
            
            [[PACERClient sharedClient] executeSearch:params sender:self];
            
        }];
        
        
        _searchPACERButton.titleLabel.font = [UIFont fontWithName:kMainFont size:16];
        _searchPACERButton.titleLabel.numberOfLines = 2;
        CGRect frame;
        frame.size.width = self.tableView.rowHeight*2.5;
        frame.size.height = self.tableView.rowHeight*.75;
        frame.origin = CGPointMake(self.tableView.center.x-frame.size.width/2., CGRectGetMaxY(self.tableView.frame)+self.tableView.frame.origin.y);
        _searchPACERButton.frame = frame;
        
        _searchPACERButton.layer.cornerRadius = 5.0;
        _searchPACERButton.imageView.transform = CGAffineTransformMakeScale(.5, .5);
    }
    
    return _searchPACERButton;
}


-(void) postSearchResults:(NSMutableArray *)results nextPage:(NSString *)nextPage
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    if(results.count > 0)
    {
        DkTSearchResultsViewController *resultsController = [[DkTSearchResultsViewController alloc] init];
        resultsController.results = results;
        resultsController.nextPage = nextPage;
        
        [self.navigationController pushViewController:resultsController animated:YES];
    }
    
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Search" message:@"No results found." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(BOOL) shouldAutorotate
{
    return NO;
}

-(PACERRegionType) regionForKey:(NSString *)key
{
    if([_states containsObject:key]) return PACERRegionTypeState;

    else if ([_appellates containsObject:key]) return PACERRegionTypeAppellate;
    
    else if ([_districts containsObject:key]) return PACERRegionTypeDistrict;
    
    else if ([_bankruptcies containsObject:key]) return PACERRegionTypeBankruptcy;
    
    else return PACERRegionTypeNone;
}

-(void) configureTableViewForCourtTypeSelection:(NSUInteger)i
{
    
    PACERRegionType regionType = _selectedRegion;
    
    _keys = [NSMutableArray array];
    
    switch(i) {
            
        case 0: {
            [_keys addObjectsFromArray:_appellates];
            [_keys addObjectsFromArray:[self alphabetizeAndCombine:PACERCourtTypeState, PACERCourtTypeCivil, PACERCourtTypeBankruptcy, NSNotFound]];
            
        } break;
        
        case PACERCourtTypeAppellate: {
            if( (regionType == PACERRegionTypeDistrict) || (regionType == PACERRegionTypeBankruptcy) || (regionType == PACERCourtTypeState) )
            {
                [self.data setObject:@"" atIndexedSubscript:2];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            }
            
            [_keys addObjectsFromArray:_appellates];
            
            
        } break;
            
        case PACERCourtTypeBankruptcy: {
            
            if(regionType == PACERRegionTypeDistrict)
            {
                [self.data setObject:@"" atIndexedSubscript:2];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            }
            
            [_keys addObjectsFromArray:_appellates];
            [_keys addObjectsFromArray:[self alphabetizeAndCombine:PACERCourtTypeState, PACERCourtTypeBankruptcy, NSNotFound]];
        } break;
            
        case PACERCourtTypeCivil:
        case PACERCourtTypeCriminal:
        case PACERCourtTypeMDL:
        {
            
            
            if(regionType == PACERRegionTypeBankruptcy)
            {
                [self.data setObject:@" " atIndexedSubscript:2];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            }
            
            [_keys addObjectsFromArray:_appellates];
            [_keys addObjectsFromArray:[self alphabetizeAndCombine:PACERCourtTypeState, PACERCourtTypeCivil, PACERCourtTypeCivil, NSNotFound]];
            
        } break;
            
        default:
        {
            
            [_keys addObjectsFromArray:_appellates];
            [_keys addObjectsFromArray:[self alphabetizeAndCombine:PACERCourtTypeState, PACERCourtTypeCivil, PACERCourtTypeBankruptcy, NSNotFound]];
        } break;
    }
    
    ((FSPopoverTableViewController *)[self.controls objectAtIndex:1]).data = _keys;
}

-(NSArray *) alphabetizeAndCombine:(PACERRegionType)firstType, ...
{
    va_list args;
    va_start(args, firstType);
    
    
    NSMutableArray *regions = [NSMutableArray array];
    
    for(PACERRegionType arg = firstType; arg != NSNotFound; arg = va_arg(args, PACERRegionType))
    {
        if(arg == PACERRegionTypeState) [regions addObjectsFromArray:_states];
        
        if(arg == PACERRegionTypeAppellate) [regions addObjectsFromArray:_appellates];
        
        if(arg == PACERRegionTypeBankruptcy) [regions addObjectsFromArray:_bankruptcies];
        
        if(arg == PACERRegionTypeDistrict) [regions addObjectsFromArray:_districts];
    }
    
    NSArray *returnArray = [regions sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    
    return returnArray;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}

-(UITextField *) textFieldWithPlaceholder:(NSString *)placeholder
{
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(self.tableView.frame.size.width-210, 0, 200,self.tableView.rowHeight)];
    field.placeholder = placeholder;
    field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    field.delegate = self;
    field.textAlignment = NSTextAlignmentRight;
    field.autocorrectionType = NO;
    field.returnKeyType = UIReturnKeyDone;
    field.clearsOnBeginEditing = YES;
    field.font = [UIFont fontWithName:kContrastFont size:16];
    field.textColor = kActiveColor;
   // field.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    return field;
}

-(FSPopoverTableViewController *)popoverForRow:(NSInteger)row keys:(NSArray *)keys
{
    
    
    CGPoint origin = CGPointMake(self.tableView.frame.size.width, self.tableView.rowHeight*(row+1));
    
    origin = [self.view convertPoint:origin fromView:self.tableView];
    
    CGRect frame = CGRectMake(origin.x-150, origin.y, 200, 300);
    
    FSPopoverTableViewSelectionBlock selectionBlock = (row == 0) ?
    
    ^(int index) {
        
        NSString *value = [keys objectAtIndex:index];
        [self.data setObject:value atIndexedSubscript:row];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [[self.tableView cellForRowAtIndexPath:indexPath].detailTextLabel setNeedsDisplay];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
        [self configureTableViewForCourtTypeSelection:index];
    }
    
    :
    
    ^(int index) {
        
        NSString *value = [keys objectAtIndex:index];
        [self.data setObject:value atIndexedSubscript:row];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [[self.tableView cellForRowAtIndexPath:indexPath].detailTextLabel setNeedsDisplay];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    };
    
    
    FSPopoverTableViewController *popover = [[FSPopoverTableViewController alloc] initWithAnchorView:self.view frame:frame selectionBlock:selectionBlock];
    
    popover.arrowLength = 20;
    popover.data = keys;
    popover.font = [UIFont fontWithName:kContrastFont size:12];
    popover.colors = @[kDarkTextColor, kInactiveColor];
    popover.borderColor = kDarkTextColor;
    popover.separatorColor = kDarkTextColor;
    
    return popover;
}

-(void) keyboardDidShow
{
    _keyboardActive = YES;
}

-(NSArray *)helpTexts
{
    if(_helpTexts == nil)
    {
        NSMutableAttributedString *attributedHelpText = [[NSMutableAttributedString alloc] initWithString:@"Enter case number. \n \nCase numbers can be entered in the following formats:" attributes:nil];
        
        NSAttributedString *boldText = [[NSAttributedString alloc] initWithString:@"\n\n   \u2023 yy-nnnnn\n   \u2023 yy-tp-nnnnn\n   \u2023 yy tp nnnnn\n   \u2023 yytpnnnnn\n   \u2023 o:yy-nnnnn\n   \u2023 o:yy-tp-nnnnn\n   \u2023 o:yy tp nnnnn\n   \u2023 o:yytpnnnnn\n" attributes:@{NSFontAttributeName:kBoldHelpFont}];
        
        [attributedHelpText appendAttributedString:boldText];
        
        NSAttributedString *yy = [[NSAttributedString alloc] initWithString:@"\nyy:" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
        
        [attributedHelpText appendAttributedString:yy];
        
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:@" case year (2 or 4 digits)"];
        [attributedHelpText appendAttributedString:text];
                                      
         NSAttributedString *nnnnn = [[NSAttributedString alloc] initWithString:@"\nnnnnn:" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
        
        [attributedHelpText appendAttributedString:nnnnn];
        
        text = [[NSAttributedString alloc] initWithString:@" case number (up to 5 digits)"];
        [attributedHelpText appendAttributedString:text];
        
         NSAttributedString *tp = [[NSAttributedString alloc] initWithString:@"\ntp:" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
        [attributedHelpText appendAttributedString:tp];
        
        text = [[NSAttributedString alloc] initWithString:@" case type (up to 2 characters)"];
        [attributedHelpText appendAttributedString:text];
        
         NSAttributedString *o = [[NSAttributedString alloc] initWithString:@"\no:" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
        [attributedHelpText appendAttributedString:o];
        
        text = [[NSAttributedString alloc] initWithString:@" office where the case was filed (1 digit)"];
        [attributedHelpText appendAttributedString:text];
        
        NSAttributedString *endText = [[NSAttributedString alloc] initWithString:@"\n\nCase type and office values are ignored for Appellate case numbers."];
        
        [attributedHelpText appendAttributedString:endText];
        
        _helpTexts = @[attributedHelpText, attributedHelpText, attributedHelpText, attributedHelpText, attributedHelpText, attributedHelpText];
    }
    
    return _helpTexts;
}

-(NSArray *)controls
{
    if(_controls == nil)
    {
        
        NSMutableArray *keys1 = [@[@"All"] mutableCopy];
        [keys1 addObjectsFromArray:_courtTypes];
        
        FSPopoverTableViewController *popover1 = [self popoverForRow:0 keys:keys1];
        
        NSMutableArray *keys2 = _keys;
        
        [keys2 insertObject:@"All" atIndex:0]; 
        
        FSPopoverTableViewController *popover2 = [self popoverForRow:1 keys:keys2];
        
        UITextField *textField1 = [self textFieldWithPlaceholder:@"e.g., 04-cv-19322"];
        textField1.attributedHelpText = [self.helpTexts objectAtIndex:4];
        
        UITextField *textField2 = [self textFieldWithPlaceholder:@"Last, First"];
        
        CKCalendarView *calendarView1 = [self makeCalendarView];
        CKCalendarView *calendarView2 = [self makeCalendarView];
        
        _controls = @[popover1, popover2, textField1, calendarView1, calendarView2, textField2];

    }
    
    return _controls;
}

-(CKCalendarView *) makeCalendarView
{
    CKCalendarView *calendarView = [[CKCalendarView alloc] initWithStartDay:startSunday];
    calendarView.center = self.tableView.center;
    calendarView.delegate = self;
    calendarView.titleFont = [UIFont fontWithName:kMainFont size:16];
    calendarView.dayOfWeekTextColor = kActiveColor;
    calendarView.dateOfWeekFont = [UIFont fontWithName:kMainFont size:13];
    [calendarView setDayOfWeekBottomColor:kInactiveColor topColor:kInactiveColor];
    
    [calendarView setInnerBorderColor:[UIColor clearColor]];
    calendarView.backgroundColor = kActiveColor;
    return calendarView;
    
}
-(void) calendar:(CKCalendarView *)calendar didSelectDate:(NSDate *)date
{
    
    [calendar removeFromSuperview];
    
    if(calendar == [self.controls objectAtIndex:3])
    {
        [self.data setObject:date atIndexedSubscript:3];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    else if (calendar == [self.controls objectAtIndex:4])
    {
        [self.data setObject:date atIndexedSubscript:4];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
    
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(int i = 0; i < self.data.count; ++i)
    {
        if(showing[i])
        {
            UIView *view = (i < 3) ? [[self.controls objectAtIndex:i] view] : [self.controls objectAtIndex:i];
            
            CGPoint point = [[touches anyObject] locationInView:view];
            
            if(![view pointInside:point withEvent:event]) [view removeFromSuperview];
        }
        
        showing[i] = FALSE;
    }
    
    
    [super touchesBegan:touches withEvent:event];
}

@end

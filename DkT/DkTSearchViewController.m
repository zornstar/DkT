 //
//  RECAPSearchViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSearchViewController.h"
#import "DkTLoginViewController.h"
#import "DkTAlertView.h"
#import "DkTTextField.h"
#import "DkTSession.h"
#import "DkTCodeManager.h"
#import "DkTSearchResultsViewController.h"
#import "DkTSearchTableView.h"

#import "FSPopoverTableViewController.h"
#import "FSButton.h"

#import "RECAPClient.h"
#import "PACERClient.h"

#import "MBProgressHUD.h"
#import "CKCalendarView.h"
#import "UIViewController+PKRevealController.h"
#import "PKRevealController.h"

#import <QuartzCore/QuartzCore.h>

NSString* const CourtTypeKey = @"court_type";
NSString* const MDLKey = @"mdl_id";
NSString* const AllRegionKey = @"all_region";
NSString* const AppelateRegionKey = @"ap_region";
NSString* const BankruptcyRegionKey = @"bk_region";
NSString* const DistrictRegionKey = @"dc_region";
NSString* const DateFiledStartKey = @"date_filed_start";
NSString* const DateTermKey = @"date_term_end";
NSString* const CaseNumberKey = @"case_no";
NSString* const PartyKey = @"party";

@interface DkTSearchViewController ()
{
    
    NSArray *_courtTypes;
    NSArray *_districts;
    NSArray *_bankruptcies;
    NSArray *_appellates;
    NSArray *_states;
    
    NSMutableDictionary *_params;
    
    
    PACERRegionType _selectedRegion;
    PACERCourtType _selectedCourtType;
    NSDateFormatter *_dateFormatter;
    NSInteger _selectedIndex;
    NSInteger _activeControl;
    BOOL _keyboardActive;
    BOOL _rotationFlag;
    
    bool showing[6];
    
}

@property (nonatomic, strong) UITextField *caseNumber;
@property (nonatomic, strong) UITextField *partyName;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic, strong) NSArray *controls;
@property (nonatomic, strong) NSArray *labels;
@property (nonatomic, strong) FSButton *searchPACERButton;
@property (nonatomic, strong) NSArray *helpTexts;
@property (nonatomic, strong) NSMutableArray *keys;

@end

@implementation DkTSearchViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        self.contentSizeForViewInPopover = CGSizeMake(400, 400);
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_dateFormatter setDateFormat:@"MM/dd/yyyy"];
        
        self.keys = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow) name:UIKeyboardDidShowNotification object:nil];
            _keyboardActive = NO;
        
        _rotationFlag = FALSE;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor activeColor];
    ((DkTTabViewController *)self.parentViewController.parentViewController).delegate = self;
    [self setup];
}

-(void) viewDidAppear:(BOOL)animated
{
    if(_rotationFlag)
    {
        [self didFinishRotationAnimation:UIInterfaceOrientationPortrait | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight];
    }
}

-(UITableView *) tableView
{
    if(_tableView == nil)
    {
        _tableView = [[DkTSearchTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
     
        _tableView.rowHeight = PAD_OR_POD(65, 52);
        
        CGRect frame;
        frame.size.height = PAD_OR_POD(_tableView.rowHeight * self.labels.count, MIN(_tableView.rowHeight * self.labels.count, self.view.frame.size.height * .65));
        frame.size.width = self.view.frame.size.width*.85;
        frame.origin = CGPointMake((self.view.frame.size.width -frame.size.width)/2.0,.06*self.view.frame.size.height);
        _tableView.frame = frame;
        _tableView.dataSource = self; _tableView.delegate = self;
        _tableView.scrollEnabled = NO;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone; _tableView.separatorColor = [UIColor clearColor];
        UIView *backgroundView = [[UIView alloc] init]; backgroundView.backgroundColor = [UIColor activeColor]; [_tableView setBackgroundView:backgroundView];
        
        
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
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.font = [UIFont fontWithName:kMainFont size:PAD_OR_POD(16, 14)];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor darkerTextColor];
    cell.contentView.backgroundColor = [UIColor inactiveColor];
    cell.detailTextLabel.textColor = [UIColor activeColor];
    cell.detailTextLabel.font = [UIFont fontWithName:kContrastFont size:PAD_OR_POD(16, 14)];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.layer.borderColor = [UIColor activeColor].CGColor;
    cell.layer.borderWidth = 2.0f;
    cell.contentView.layer.borderColor = [UIColor activeColor].CGColor;
    cell.contentView.layer.borderWidth = 2.0f;
    cell.contentView.layer.cornerRadius = 5.0f;
    cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    cell.contentView.autoresizesSubviews = YES;
    cell.backgroundView.backgroundColor =  [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    [cell.contentView addGestureRecognizer:self.longPress];
    cell.clipsToBounds = YES;
    
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
        cell.detailTextLabel.text = @"";
        DkTTextField *textField = [self.controls objectAtIndex:indexPath.row];
        [cell.contentView addSubview:textField];
    }
    
    cell.contentView.attributedHelpText = [self.helpTexts objectAtIndex:indexPath.row];
   
    
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
        [popover reloadData];
        [popover present];
    }
    
    if( (indexPath.row == 3) || (indexPath.row == 4) )
    {
        
        CKCalendarView *calendar = [self.controls objectAtIndex:indexPath.row];
        calendar.center = self.tableView.center;
        [self.view addSubview:calendar];
    }
    
}


-(void) setup
{
#define DkTCourtTypeCreate(_name, _code) @{@"name":_name, @"code":_code}
    
    _courtTypes            = @[DkTCourtTypeCreate(@"All",@"all"),
                               DkTCourtTypeCreate(@"Appellate", @"ap"),
                               DkTCourtTypeCreate(@"Bankruptcy", @"bk"),
                               DkTCourtTypeCreate(@"Civil", @"cv"),
                               DkTCourtTypeCreate(@"Criminal", @"cr"),
                               DkTCourtTypeCreate(@"Multi-District", @"jpml")];
    
    _appellates            = [DkTCodeManager valuesForKey:DkTCodeSearchDisplayKey types:DkTCodeTypeAppellateCourt];
    _districts              = [DkTCodeManager valuesForKey:DkTCodeSearchDisplayKey types:DkTCodeTypeDistrictCourt];
    _states                = [DkTCodeManager valuesForKey:DkTCodeSearchDisplayKey types:DkTCodeTypeRegion];
    
    _labels = @[@"Case Type", @"Region", @"Case Number", @"Date Filed", @"Date Closed", @"Party Name"];
    
    _data = [NSMutableArray array];
    
    for (NSInteger i = 0; i < _labels.count; ++i)
    {
        [_data addObject:[NSNull null]];
        showing[i] = FALSE;
    }
    
    self.tableView = [self tableView];
    self.controls = [self controls];
    
    _selectedCourtType = -1;
    [self configureForCourtTypeSelection:0];
    
    

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.searchPACERButton];
}

-(NSDictionary *) pacerParameters
{
    _params = [@{CourtTypeKey : @"",
                 CaseNumberKey : @"",
                 DateFiledStartKey : @"",
                 DateTermKey : @"",
                 PartyKey : @""} mutableCopy];
    
    for(int i = 0; i < self.data.count; ++i)
    {
        NSString *str = [self valueForRow:i];
        
        if(str.length == 0) str = @"";
        
        
            switch (i) {
                case 0: {
                    
                
                    NSArray *array = [_courtTypes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(%K == %@)", @"name", str]];
                    
                    if(array.count > 0)
                    {
                        str = [[array objectAtIndex:0] objectForKey:@"code"];
                    }
                    
                    else str = @"all";
                    
                    [_params setObject:str forKey:CourtTypeKey];
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
                            key = @"dc_region";
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
                    
                    NSString *value = (str.length > 0) ? [DkTCodeManager translateCode:str inputFormat:DkTCodeSearchDisplayKey outputFormat:DkTCodePACERSearchKey] : @"";
                   [_params setObject:value forKey:key];
                    
                }
                    
                    break;
                case 2:
                    [_params setObject:str forKey:CaseNumberKey];
                    break;
                case 3:
                    [_params setObject:str forKey:DateFiledStartKey];
                    break;
                case 4:
                    [_params setObject:str forKey:DateTermKey];
                    break;
                case 5:
                    [_params setObject:str forKey:PartyKey];
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
        NSString *str = [[(DkTTextField *)[self.controls objectAtIndex:i] text] copy];
        return str;
    }
    
    else if (cell.detailTextLabel.text.length > 1) return [cell.detailTextLabel.text copy];
    
    return @"";
}


-(FSButton *) searchPACERButton
{
    if(_searchPACERButton == nil)
    {
        NSArray *colors = @[[UIColor inactiveColor], [UIColor darkerTextColor]];
        _searchPACERButton = [FSButton buttonWithIcon:kSearchSmallImage colors:colors title:PAD_OR_POD(@"Search\nPACER", @"PACER")   actionBlock:^{
            
            if([self connectivityStatus]) {
               
                NSDictionary *params = [self pacerParameters];
                
                //if([self validateSearch:params])
                {
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.color = [UIColor clearColor];
                    
                    [[PACERClient sharedClient] executeSearch:params sender:self];
                }
            }
            
            
        }];
        
        
        _searchPACERButton.titleLabel.font = [UIFont fontWithName:kMainFont size:16];
        _searchPACERButton.titleLabel.numberOfLines = 2;
        _searchPACERButton.helpText = @"Search PACER for dockets matching search parameters.";
        CGRect frame;
        frame.size.width = self.tableView.rowHeight*2.5;
        frame.size.height = self.tableView.rowHeight*.75;
        frame.origin = CGPointMake(self.tableView.center.x-frame.size.width/2., CGRectGetMaxY(self.tableView.frame)+self.tableView.frame.origin.y);
        _searchPACERButton.frame = frame;
        [_searchPACERButton setIconSpacing:15.];
        _searchPACERButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        _searchPACERButton.layer.cornerRadius = 5.0;
        _searchPACERButton.imageView.transform = CGAffineTransformMakeScale(.5, .5);
    }
    
    return _searchPACERButton;
}

/*
-(BOOL) validateSearch:(NSDictionary *)params
{
    BOOL valid = FALSE;
    int i = 2;
    
    while (!valid) {
        
        valid = [self.controls objectAtIndex:i] != nil;
    }

    return valid;
}*/

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
        DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Search" andMessage:@"No search results found."];
        
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            
            [alertView dismissAnimated:YES];
            
        }];
        
        [alertView show];
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

-(void) configureForCourtTypeSelection:(NSInteger)i
{
    
    if(i == _selectedCourtType) return;

    [self.data setObject:@"" atIndexedSubscript:1];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    [[self.tableView cellForRowAtIndexPath:indexPath].detailTextLabel setNeedsDisplay];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    
    _selectedCourtType = i;
    [self.keys removeAllObjects];
    
    switch (i) {
        case 0: {
            [self.keys addObjectsFromArray:_states];
        }
            break;
        case 1: {
            [self.keys addObjectsFromArray:_appellates];
        }   break;
        case 2:
        case 3:
        case 4:
        case 5: {
            
            NSArray *regions = [DkTCodeManager valuesForKey:DkTCodeSearchDisplayKey type:DkTCodeTypeRegion];
            
            NSMutableSet *set = [NSMutableSet setWithArray:_districts];
            [set addObjectsFromArray:regions];
            NSArray *orderedKeys = [[set allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            
            [self.keys addObjectsFromArray:_appellates];
            [self.keys addObjectsFromArray:orderedKeys];
        }
            break;
    
        default: {
            [self.keys addObjectsFromArray:_states];
        }
            break;
    }
    
    
    ((FSPopoverTableViewController *)[self.controls objectAtIndex:1]).data = self.keys;
}


-(NSArray *) alphabetizeAndCombine:(PACERRegionType)firstType, ...
{
    va_list args;
    va_start(args, firstType);
    
    
    NSMutableArray *regions = [NSMutableArray array];
    
    for(NSInteger arg = firstType; arg != NSNotFound; arg = va_arg(args, PACERRegionType))
    {
        if(arg == PACERRegionTypeState) [regions addObjectsFromArray:_states];
        
        if(arg == PACERRegionTypeAppellate) [regions addObjectsFromArray:_appellates];
        
        if(arg == PACERRegionTypeBankruptcy) [regions addObjectsFromArray:_districts];
        
        if(arg == PACERRegionTypeDistrict) [regions addObjectsFromArray:_districts];
    }
    
    NSArray *returnArray = [regions sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    
    return returnArray;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self.tableView setContentOffset:CGPointZero animated:YES];
    return YES;
}

-(DkTTextField *) textFieldWithPlaceholder:(NSString *)placeholder
{
    DkTTextField *field = [[DkTTextField alloc] initWithFrame:CGRectMake(self.tableView.frame.size.width-210, 0, 200,self.tableView.rowHeight)];
    field.placeholder = placeholder;
    field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    field.delegate = self;
    field.textAlignment = NSTextAlignmentRight;
    field.autocorrectionType = NO;
    field.returnKeyType = UIReturnKeyDone;
    field.clearsOnBeginEditing = NO;
    field.font = [UIFont fontWithName:kContrastFont size:PAD_OR_POD(16, 13)];
    field.textColor = [UIColor activeColor];
    
    //field.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    return field;
}

-(FSPopoverTableViewController *)popoverForRow:(NSInteger)row keys:(NSArray *)keys
{
    
    
    CGPoint origin = CGPointMake(self.tableView.frame.size.width, self.tableView.rowHeight*(row+1));
    
    origin = [self.view convertPoint:origin fromView:self.tableView];
    
    CGRect frame = CGRectMake(origin.x-150, origin.y, PAD_OR_POD(200, 160), PAD_OR_POD(250, 250));
    
    FSPopoverTableViewSelectionBlock selectionBlock = (row == 0) ?
    
    ^(int index) {
        
        NSString *value = [keys objectAtIndex:index];
        [self.data setObject:value atIndexedSubscript:row];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [[self.tableView cellForRowAtIndexPath:indexPath].detailTextLabel setNeedsDisplay];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
        [self configureForCourtTypeSelection:index];
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
    popover.colors = @[[UIColor darkerTextColor], [UIColor inactiveColor]];
    popover.borderColor = [UIColor darkerTextColor];
    popover.separatorColor = [UIColor darkerTextColor];
    
    return popover;
}

-(void) keyboardDidShow
{
    _keyboardActive = YES;
}

-(BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
    return NO;
}
-(NSArray *)helpTexts
{
    if(_helpTexts == nil)
    {
        
        NSMutableAttributedString *attributedHelpText0 = [[NSMutableAttributedString alloc] initWithString:@"Select case type." attributes:nil];
        
        NSMutableAttributedString *attributedHelpText1 = [[NSMutableAttributedString alloc] initWithString:@"Select the jurisdiction." attributes:nil];
        
        NSMutableAttributedString *attributedHelpText2 = [[NSMutableAttributedString alloc] initWithString:@"Case numbers can be entered in the following formats:" attributes:nil];
        
        NSAttributedString *boldText = [[NSAttributedString alloc] initWithString:@"\n\n   \u2023 yy-nnnnn\n   \u2023 yy-tp-nnnnn\n   \u2023 yy tp nnnnn\n   \u2023 yytpnnnnn\n   \u2023 o:yy-nnnnn\n   \u2023 o:yy-tp-nnnnn\n   \u2023 o:yy tp nnnnn\n   \u2023 o:yytpnnnnn\n" attributes:@{NSFontAttributeName:kBoldHelpFont}];
        
        [attributedHelpText2 appendAttributedString:boldText];
        
        NSAttributedString *yy = [[NSAttributedString alloc] initWithString:@"\nyy:" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
        
        [attributedHelpText2 appendAttributedString:yy];
        
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:@" case year (2 or 4 digits)"];
        [attributedHelpText2 appendAttributedString:text];
                                      
         NSAttributedString *nnnnn = [[NSAttributedString alloc] initWithString:@"\nnnnnn:" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
        
        [attributedHelpText2 appendAttributedString:nnnnn];
        
        text = [[NSAttributedString alloc] initWithString:@" case number (up to 5 digits)"];
        [attributedHelpText2 appendAttributedString:text];
        
         NSAttributedString *tp = [[NSAttributedString alloc] initWithString:@"\ntp:" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
        [attributedHelpText2 appendAttributedString:tp];
        
        text = [[NSAttributedString alloc] initWithString:@" case type (up to 2 characters)"];
        [attributedHelpText2 appendAttributedString:text];
        
         NSAttributedString *o = [[NSAttributedString alloc] initWithString:@"\no:" attributes:@{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
        [attributedHelpText2 appendAttributedString:o];
        
        text = [[NSAttributedString alloc] initWithString:@" office where the case was filed (1 digit)"];
        [attributedHelpText2 appendAttributedString:text];
        
        NSAttributedString *endText = [[NSAttributedString alloc] initWithString:@"\n\nCase type and office values are ignored for appellate case numbers."];
        
        [attributedHelpText2 appendAttributedString:endText];
        
        NSMutableAttributedString *attributedHelpText3 = [[NSMutableAttributedString alloc] initWithString:@"Date the case opened (or after)." attributes:nil];
        
        NSMutableAttributedString *attributedHelpText4 = [[NSMutableAttributedString alloc] initWithString:@"Date the case closed (or before)." attributes:nil];
        
        
        NSMutableAttributedString *attributedHelpText5 = [[NSMutableAttributedString alloc] initWithString:@"Last name and first name of a party." attributes:nil];
        
        
        _helpTexts = @[attributedHelpText0, attributedHelpText1, attributedHelpText2, attributedHelpText3, attributedHelpText4, attributedHelpText5];
    }
    
    return _helpTexts;
}

-(NSArray *)controls
{
    if(_controls == nil)
    {
        
        FSPopoverTableViewController *popover1 = [self popoverForRow:0 keys:[_courtTypes valueForKey:@"name"]];
        
        NSMutableArray *keys2 = self.keys;
        
        FSPopoverTableViewController *popover2 = [self popoverForRow:1 keys:keys2];
        
        DkTTextField *textField1 = [self textFieldWithPlaceholder:@"e.g., 04-cv-19322"];
        textField1.autocorrectionType = UITextAutocorrectionTypeNo;
        
        DkTTextField *textField2 = [self textFieldWithPlaceholder:@"Last, First"];
        textField2.autocorrectionType = UITextAutocorrectionTypeNo;
        
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
    calendarView.dayOfWeekTextColor = [UIColor activeColor];
    calendarView.dateOfWeekFont = [UIFont fontWithName:kMainFont size:13];
    [calendarView setDayOfWeekBottomColor:[UIColor inactiveColor] topColor:[UIColor inactiveColor]];
    
    [calendarView setInnerBorderColor:[UIColor clearColor]];
    calendarView.backgroundColor = [UIColor activeColor];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
       calendarView.frame = CGRectInset(calendarView.frame, 10, 10);
        calendarView.backgroundColor = [UIColor inactiveColorDark];
        
    }
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

-(void) viewWillAppear:(BOOL)animated
{
    [self.tableView setContentOffset:CGPointZero];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self hideAllActiveControls];
    
    [super touchesBegan:touches withEvent:event];
} 

-(void) hideAllActiveControls
{
    for(int i = 0; i < self.data.count; ++i)
    {
        if(showing[i])
        {
            UIView *view;
            if(i < 2) view = [[self.controls objectAtIndex:i] view];
            
            else view = [self.controls objectAtIndex:i];
            
            
           // CGPoint point = [[touches anyObject] locationInView:view];
            
            //if(![view pointInside:point withEvent:event])
            {
                if((i == 2) || (i == 5)) [view resignFirstResponder];
                
                else [view removeFromSuperview];
            }
        }
        
        showing[i] = FALSE;
    }

}
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self hideAllActiveControls];
    
    if(textField == [self.controls objectAtIndex:2]) showing[2] = TRUE;
    
    else
    {
        showing[5] = TRUE;
    }
    
    return TRUE;
}

-(void) textFieldDidEndEditing:(UITextField *)textField
{
    [self.tableView setContentOffset:CGPointZero animated:YES];
}

-(void) textFieldDidBeginEditing:(UITextField *)textField
{
    if(textField == [self.controls objectAtIndex:5]) {
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone || UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
        {
            [self.tableView setContentOffset:CGPointMake(0, 80) animated:YES];
        }
    }
    
}


-(void)didFinishRotationAnimation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    
    UITextField *tf1 = [self.controls objectAtIndex:2];
    UITextField *tf2 = [self.controls objectAtIndex:5];
    
    if (self.isViewLoaded && self.view.window && !_rotationFlag) {
        
        
        [UIView animateWithDuration:.2 animations:^{
            
            tf1.frame = CGRectMake(self.tableView.frame.size.width-210, 0, 200,self.tableView.rowHeight);
            tf2.frame = CGRectMake(self.tableView.frame.size.width-210, 0, 200,self.tableView.rowHeight);
        }];
        
        _rotationFlag = FALSE;
    }
    
    else if (_rotationFlag)
    {
        tf1.frame = CGRectMake(self.tableView.frame.size.width-210, 0, 200,self.tableView.rowHeight);
        tf2.frame = CGRectMake(self.tableView.frame.size.width-210, 0, 200,self.tableView.rowHeight);
        
        [self.tableView setNeedsLayout];
        
        _rotationFlag = FALSE;
    }
    
    else _rotationFlag = TRUE;
    
    

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
            
            PKRevealController *revealController = PAD_OR_POD(self.parentViewController.parentViewController.revealController, self.parentViewController.parentViewController.revealController);
            [revealController showViewController:revealController.leftViewController animated:YES completion:^(BOOL finished) {
                
            }];
            
            
        }];
        
        
        [alertView show];
        return FALSE;
    }
    
    return TRUE;
    
}


-(UILongPressGestureRecognizer *)longPress
{
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    return longPress;
}

-(void) handleLongPress:(UIGestureRecognizer *)sender
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
        
        if((indexPath.row == 2) || (indexPath.row == 5))
        {
            UITextField *tf = [self.controls objectAtIndex:indexPath.row];
            tf.text = @"";
        }
        
        else
        {
            [self.data replaceObjectAtIndex:indexPath.row withObject:[NSNull null]];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

@end
 
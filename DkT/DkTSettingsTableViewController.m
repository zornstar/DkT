//
//  RECAPSettingsTableViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 6/26/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSettingsTableViewController.h"
#import "DkTSettings.h"
#import "DkTConstants.h"
#import "MBSwitch.h"
#import "UIControl+Blocks.h"
#import <QuartzCore/QuartzCore.h>

@interface DkTSettingsTableViewController ()

@property (nonatomic, strong) NSArray *controls;
@property (nonatomic, strong) NSArray *names;
@property (nonatomic, strong) NSArray *descriptions;

@end

@implementation DkTSettingsTableViewController

- (id)initWithSettingsCell:(DkTSettingsCell *)cell
{
    self = [super initWithSettingsCell:cell];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    [self setup];
}

-(void) setup
{
    self.controls = @[[self switchWithKey:DkTSettingsEnabledKey], [self switchWithKey:DkTSettingsReceiptKey], [self switchWithKey:DkTSettingsQuickLoginKey]];
    self.names = @[@"Enable RECAP", @"Receipt Notifications", @"Auto-Login"];
    self.descriptions = @[@"Upload to and prompt for downloads from RECAP when available", @"Display receipt prior to download", @"Automatically login as the last user"];
    self.contentView = self.tableView;
}


-(MBSwitch *) switchWithKey:(NSString *)key
{
    MBSwitch *mySwitch = [[MBSwitch alloc] initWithFrame:CGRectMake(0, 0, 31, 50)];
    
    BOOL value = [[[DkTSettings sharedSettings] valueForKey:key] boolValue];
    
    mySwitch.on = value;
    mySwitch.tintColor = kActiveColorLight;
    mySwitch.offTintColor = kActiveColorLight;
    mySwitch.onTintColor = kInactiveColorDark;
    mySwitch.animateWithTouchEnabled = NO;
    [mySwitch addActionForControlEvents:UIControlEventValueChanged usingBlock:^(UIControl *sender, UIEvent *event) {
        
        
        [[DkTSettings sharedSettings] setBoolValue:((MBSwitch *)sender).on forKey:key];
        
    }];
    
    
    return mySwitch;
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.textLabel.font = [UIFont fontWithName:kMainFont size:12];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor clearColor];
        cell.accessoryView.backgroundColor = [UIColor clearColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = kInactiveColor;
        cell.textLabel.numberOfLines = 2;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.accessoryView = [self.controls objectAtIndex:indexPath.row];
    cell.textLabel.text = [self.names objectAtIndex:indexPath.row];
    [cell.textLabel sizeToFit];
    
    
    return cell;
}

-(UITableView *) tableView
{
    if(_tableView == nil)
    {
        CGFloat x = CGRectGetMaxX(self.cell.frame), y = CGRectGetMaxY(self.cell.frame);
        
        CGRect frame = CGRectMake(x,y, self.containerView.frame.size.width - x, self.containerView.frame.size.height - y);
        _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        _tableView.layer.cornerRadius = 5.0;
        _tableView.delegate = self;
        _tableView.scrollEnabled = NO;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
    }
    
    return _tableView;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.controls.count;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIControl *control = [self.controls objectAtIndex:indexPath.row];
    
    if([control isKindOfClass:[MBSwitch class]])
    {
        ((MBSwitch *)control).on = !((MBSwitch *)control).on;
    }
}

@end

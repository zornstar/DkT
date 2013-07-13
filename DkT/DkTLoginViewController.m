//
//  RECAPLoginViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTLoginViewController.h"
#import "DkTSearchViewController.h"
#import "DkTUser.h"
#import "DkTSession.h"
#import "FSButton.h"
#import "PACERClient.h"
#import "MBProgressHUD.h"
#import "UIImage+Utilities.h"
#import "DkTSidePanelController.h"
#import "DkTSessionManager.h"
#import "DkTLoginViewController.h"
#import "UIResponder+FirstResponder.h"

#import <QuartzCore/QuartzCore.h>


@interface CostLabel : UILabel

@end

@implementation CostLabel : UILabel

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.text = [NSString stringWithFormat:@"Cost: %f",[DkTSession currentSession].cost];
}
@end

@interface DkTLoginViewController ()

@property (nonatomic, strong)  DkTSession *selectedSession;
@property (nonatomic, strong) UIView *activeView;

@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *clientField;

@property (nonatomic, strong) FSButton *loginButton;
@property (nonatomic, strong) FSButton *sessionButton;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *loginView;
@property (nonatomic, strong) UITableView *usersView;
@property (nonatomic, strong) UIView *loggedInView;
@property (nonatomic, strong) NSArray *recentSessions;


@end


@implementation DkTLoginViewController

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
	
    _selectedSession = nil;
    self.contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizesSubviews = YES;
    self.contentView.autoresizesSubviews = YES;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    [self.contentView addSubview:self.loginView];
    [self.view addSubview:self.contentView];
    [self.contentView addSubview:self.loginButton];
    [self.contentView addSubview:self.sessionButton];
    
    
    _activeView = self.loginView;
    
}

-(UIView *) loginView
{
    if(_loginView == nil)
    {
        self.usernameField = [self textFieldWithPassword:NO placeholder:@" Enter User Name" origin:CGPointMake(self.view.frame.size.width*.05, 0) icon:[[UIImage imageNamed:@"user"] imageWithColor:[UIColor lightGrayColor]]];
        self.usernameField.helpText = @"PACER username";
        
        CGPoint nextOrigin = CGPointMake(self.view.frame.size.width*.05, CGRectGetMaxY(self.usernameField.frame)+self.usernameField.frame.size.height);
        
        self.passwordField = [self textFieldWithPassword:YES placeholder:@" Enter Password" origin:nextOrigin icon:[[UIImage imageNamed:@"lock"] imageWithColor:[UIColor lightGrayColor]]];
        self.passwordField.helpText = @"PACER password";
        
        nextOrigin = CGPointMake(self.view.frame.size.width*.05, CGRectGetMaxY(self.passwordField.frame)+self.passwordField.frame.size.height);
        
        self.clientField = [self textFieldWithPassword:YES placeholder:@" Enter Client (optional)" origin:nextOrigin icon:nil];
        self.clientField.helpText = @"Enter Client field (optional).";
        
        _loginView = [[UIView alloc] initWithFrame:CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.usernameField.frame.size.width, CGRectGetMaxY(self.clientField.frame)-self.usernameField.frame.origin.x)];
        _loginView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [_loginView addSubview:self.usernameField];
        [_loginView addSubview:self.passwordField];
        [_loginView addSubview:self.clientField];
    }
    
    return _loginView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UITextField *) textFieldWithPassword:(BOOL)password placeholder:(NSString *)placeholder origin:(CGPoint)origin icon:(UIImage *)icon
{
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width*.9, 32)];
    textField.placeholder = placeholder;
    textField.clearsOnBeginEditing = YES;
    textField.secureTextEntry = password;
    CGRect frame = textField.frame;
    frame.origin = origin;
    textField.frame = frame;
    textField.delegate = self;
    textField.backgroundColor = kInactiveColor;
    textField.layer.cornerRadius = 5.0;
    textField.font = [UIFont fontWithName:kLightFont size:12];
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    if(icon)
    {
        UIImageView *iconView = [[UIImageView alloc] init];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        CGRect frame = CGRectMake(textField.frame.size.width-textField.frame.size.height, .2*textField.frame.size.height, .6*textField.frame.size.height, .6*textField.frame.size.height);
        iconView.frame = frame;
        iconView.image = icon;
        iconView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        
        [textField addSubview:iconView];
    }
    
    return textField;
}


-(void) handleLogin:(BOOL)success
{
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    if(success)
    {
        
        
        [((DkTSidePanelController *)self.parentViewController) resignWithCompletion:^(BOOL finished) {
            
            
            [self toggleLoggedInView:YES];
        }];
        
    }
    
    else
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"Error Logging Into PACER. Please check username and password." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        self.view.hidden = NO;
    }
}
+(void) presentAsPopover:(UIViewController *)viewController size:(CGSize)size
{
    DkTLoginViewController *login = [[DkTLoginViewController alloc] init];
    
    
    login.view.layer.cornerRadius = 5.0;
    
    
    for(UIView *subview in viewController.view.subviews)
    {
        
        subview.userInteractionEnabled = NO;
        subview.alpha = .3;
    }
    
    [viewController addChildViewController:login];
    [viewController.view addSubview:login.view];
    login.view.center = CGPointMake(viewController.view.center.x, viewController.view.center.y*.66);
    
}

-(UIButton *) loginButton
{
    if(_loginButton == nil)
    {
        NSArray *colors = @[kActiveColor, kInactiveColor];
        _loginButton = [FSButton buttonWithIcon:kLoginButtonImage colors:colors title:@"Login" actionBlock:^{
            
            if(_selectedSession != nil)
            {
                //hud.color = kActiveColor;
                [[PACERClient sharedClient] loginForSession:_selectedSession sender:self];
            }
            else if(self.usernameField.text.length < 1)
            {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Input Error" message:@"Please type in a username." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [errorAlert show];
            }
            
            else if(self.passwordField.text.length < 1)
            {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Input Error" message:@"Please type in a password" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [errorAlert show];
            }
            
            else
            {
                
                DkTUser *newUser = [[DkTUser alloc] init];
                newUser.username = self.usernameField.text;
                newUser.password = self.passwordField.text;
                DkTSession *session = [[DkTSession alloc] init];
                session.user = newUser;
                session.client = (self.clientField.text.length > 0) ? self.clientField.text : @"";
                [[PACERClient sharedClient] loginForSession:session sender:self];
                
            }
            
        }];
        
        _loginButton.titleLabel.font = [UIFont fontWithName:kMainFont size:16];
        _loginButton.layer.cornerRadius = 5.0;
        
        CGFloat width = self.clientField.frame.size.width*.9;
        _loginButton.frame = CGRectMake(CGRectGetMaxX(self.clientField.frame)-width, CGRectGetMaxY(self.clientField.frame)+self.clientField.frame.size.height, width, 50);
        _loginButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _loginButton.imageView.transform = CGAffineTransformMakeScale(.5, .5);
        _loginButton.helpText = @"Login to PACER";
    }
    
    return _loginButton;
}

-(UIButton *) sessionButton
{
    if(_sessionButton == nil) {
        
        NSArray *colors = @[kActiveColor, kInactiveColor];
        
        FSButton *sessionButton = [FSButton buttonWithIcon:kSessionButtonImage colors:colors title:@"" actionBlock:^{
            
            [self toggleUserView];
        }];
        
        CGFloat width = self.clientField.frame.size.width*.075;
        sessionButton.layer.cornerRadius = 5.0;
        sessionButton.frame = CGRectMake(CGRectGetMinX(self.clientField.frame), CGRectGetMaxY(self.clientField.frame)+self.clientField.frame.size.height, width, 50);
        _sessionButton = sessionButton;
        _sessionButton.helpText = @"Login as a recent user";
        
    }
    
    return _sessionButton;
}

-(void) toggleUserView
{
    if([self.usersView superview] == nil)
    {
        _activeView.hidden = YES;
        self.recentSessions = [self getRecentSessions];
        [self.usersView reloadData];
        [self.contentView addSubview:self.usersView];
        
    }
    
    else
    {
        _activeView.hidden = NO;
        [self.usersView removeFromSuperview];
    }


    [self.sessionButton invert];
}

-(void) toggleLoggedInView:(BOOL)visible
{
    
    if(visible)
    {
        if([self.usersView superview])
        {
            [self.sessionButton invert]; [self.usersView removeFromSuperview];
        }
        
        else [self.loginView removeFromSuperview];
                
        [self.contentView addSubview:self.loggedInView];
        
        
        _activeView = self.loggedInView;
        
    }
    
    else
    {
        [self.loggedInView removeFromSuperview];
        [self.contentView addSubview:self.loginView];
        self.loggedInView = nil;
        _activeView = self.loginView;
    }

}


-(NSArray *) getRecentSessions
{
    NSMutableArray *recentSessions = [NSMutableArray array];
    NSArray *sessions = [[DkTSessionManager sharedManager] sessions];
    
    int max = MIN(sessions.count, 4);
    
    for(int i = 0; i < max; ++i)
    {
        [recentSessions addObject:[sessions objectAtIndex:i]];
    }
    
    return recentSessions;
}

-(UITableView *)usersView
{
    if(_usersView == nil)
    {
        _usersView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        
        _usersView.rowHeight = 45;
        
        CGRect frame;
        frame.size.height = _usersView.rowHeight * MAX(self.recentSessions.count,1);
        frame.size.width = self.usernameField.frame.size.width;
        frame.origin = self.usernameField.frame.origin;
        _usersView.frame = frame;
        
        _usersView.dataSource = self;
        _usersView.delegate = self;
        _usersView.scrollEnabled = YES;
        _usersView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _usersView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _usersView.scrollEnabled = NO;
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = kInactiveColor;
        [_usersView setBackgroundView:backgroundView];
        _usersView.clipsToBounds = YES;
        _usersView.layer.cornerRadius = 5.0;
    }
    
    return _usersView;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        cell.contentView.helpText = @"Select a recent user/client and click the Login button to login as a recent user (no password needed).";
        cell.textLabel.font = [UIFont fontWithName:kLightFont size:16];
        cell.textLabel.backgroundColor = kInactiveColor;
        cell.textLabel.textColor = kDarkTextColor;
        cell.detailTextLabel.font = [UIFont fontWithName:kContrastFont size:12];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    
    
    if(indexPath.row == self.recentSessions.count - 1)
    {
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:cell.bounds
                                                       byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight)
                                                             cornerRadii:CGSizeMake(5.0, 5.0)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = cell.contentView.bounds;
        maskLayer.path = maskPath.CGPath;
        cell.layer.mask = maskLayer;
    }
    
    if(indexPath.row == 0)
    {
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:cell.contentView.bounds
                                                       byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                                             cornerRadii:CGSizeMake(5.0, 5.0)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = cell.bounds;
        maskLayer.path = maskPath.CGPath;
        cell.contentView.layer.mask = maskLayer;
    }
    
    
    if(self.recentSessions.count == 0)
    {
        
        cell.textLabel.text = @"No recent logins.";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    
    else
    {
        DkTSession *session = [self.recentSessions objectAtIndex:indexPath.row];
        cell.contentView.backgroundColor = (indexPath.row%2 == 0) ? kInactiveColor : kInactiveColorDark;
        
        cell.imageView.image = [kDocketImage imageWithColor:kActiveColor];
        cell.imageView.transform = CGAffineTransformMakeScale(.5, .5);
        cell.textLabel.text = session.user.username;
        cell.detailTextLabel.textColor = (indexPath.row%2 == 0) ? kActiveColor : kInactiveColor;
    }
    
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return MAX(self.recentSessions.count, 1);
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedSession = [self.recentSessions objectAtIndex:indexPath.row];
}

-(UIView *) loggedInView
{
    if(_loggedInView == nil)
    {
        _loggedInView = [[UIView alloc] initWithFrame:self.loginView.frame];
        
        UILabel *loggedInAs = [[UILabel alloc] initWithFrame:self.usernameField.frame];
        loggedInAs.text = [NSString stringWithFormat:@"User: %@",[DkTSession currentSession].user.username];
        loggedInAs.font = [UIFont fontWithName:kContrastFont size:14];
        loggedInAs.backgroundColor = [UIColor clearColor];
        
        UILabel *client = [[UILabel alloc] initWithFrame:self.passwordField.frame];
        client.text = [NSString stringWithFormat:@"Client: %@",[DkTSession currentSession].client];
        client.font = [UIFont fontWithName:kContrastFont size:14];
        client.backgroundColor = [UIColor clearColor];
        
        CostLabel *cost = [[CostLabel alloc] initWithFrame:self.clientField.frame];
        
        cost.text = [NSString stringWithFormat:@"Cost: %@",[[DkTSession currentSession] costString]];
        cost.font = [UIFont fontWithName:kContrastFont size:14];
        cost.backgroundColor = [UIColor clearColor];
        [[DkTSession currentSession] addObserver:cost forKeyPath:@"costString" options:NSKeyValueObservingOptionNew context:nil];
        
        [_loggedInView addSubview:loggedInAs];
        [_loggedInView addSubview:client];
        [_loggedInView addSubview:cost];
    }
    
    return _loggedInView;
}

@end


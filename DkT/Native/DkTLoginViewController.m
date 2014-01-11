
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTLoginViewController.h"


#import "FSButton.h"
#import "PACERClient.h"
#import "MBProgressHUD.h"
#import "UIImage+Utilities.h"
#import "UIView+Utilities.h"
#import "UIResponder+FirstResponder.h"
#import "UIViewController+MJPopupViewController.h"
#import "DkTSettings.h"
#import "DkTSearchViewController.h"
#import "DkTUser.h"
#import "DkTSession.h"
#import "DkTSidePanelController.h"
#import "DkTSessionManager.h"
#import "DkTLoginViewController.h"
#import "DkTAlertView.h"
#import "DkTTextField.h"
#import "DkTSettingsCell.h"
#import <QuartzCore/QuartzCore.h>

#define LOGIN_FRAME PAD_OR_POD(CGRectMake(30, 0, 200, 200), CGRectMake(20,0,200,200))

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

@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *clientField;

@property (nonatomic, strong) FSButton *loginButton;
@property (nonatomic, strong) FSButton *logoutButton;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *activeView;

@property (nonatomic, strong) UIView *loginView;
@property (nonatomic, strong) UITableView *usersView;
@property (nonatomic, strong) UIView *loggedInView;
@property (nonatomic, strong) NSArray *recentSessions;


@property (nonatomic) DkTPanelVisibility panelChange;
@property (nonatomic) DkTPanelVisibility currentPanel;

@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTap;

@end


@implementation DkTLoginViewController

- (id)init {
    self = [super init];
    if (self) {
        _modal = NO;
        _panelChange = DkTLoginPanelVisible;
        _currentPanel = DkTNoPanelVisible;
        [[DkTSession sharedInstance] setDelegate:self];
        
        static dispatch_once_t onceToken;
        
        dispatch_once(&onceToken, ^{
            [self checkAutoLogin];
        });
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(forceLogout:)
                                                     name:@"forceLogout"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkAutoLogin)
                                                     name:@"autoLogin"
                                                   object:nil];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
	
    _selectedSession = nil;
    
    self.view.backgroundColor = [UIColor inactiveColorDark];
    self.view.autoresizesSubviews = YES;
    self.view.layer.cornerRadius = 5.0f;
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    if([DkTSession currentSession].user.username.length > 0) _status = DkTLoggedIn;
}


-(UIView *) contentView
{
    if(_contentView == nil)
    {
        _contentView = [[UIView alloc] initWithFrame:self.view.bounds];
        _contentView.layer.cornerRadius = 5.0f;
        _contentView.backgroundColor = [UIColor inactiveColorDark];
        _contentView.autoresizesSubviews = YES;
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _contentView;
}

-(void) displayLoggingIn
{
    MBProgressHUD *hud;
    
    if((hud = [MBProgressHUD HUDForView:self.view]))
    {
        [self.view bringSubviewToFront:hud];
    }
    
    else
    {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.color = [UIColor clearColor];
    }
}
-(void) checkAutoLogin
{
    BOOL login = [[[DkTSettings sharedSettings] valueForKey:DkTSettingsAutoLoginKey] boolValue];
    
    if(login)
    {
        [[PACERClient sharedClient] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
           
            if( (status == AFNetworkReachabilityStatusReachableViaWWAN) || (status == AFNetworkReachabilityStatusReachableViaWiFi) )
            {
                DkTSession *session = [DkTSessionManager lastSession];
                if(session.user.username.length > 0)
                {
                    _status = DkTLoggingIn;
                   [[PACERClient sharedClient] loginForSession:session sender:self];
                }
            }
            
            else [MBProgressHUD hideAllHUDsForView:self.contentView animated:YES];
            
            [[PACERClient sharedClient] setReachabilityStatusChangeBlock:nil];
        }];
    }
}

-(UIView *) loginView
{
    if(_loginView == nil)
    {
        _loginView = [[UIView alloc] initWithFrame:LOGIN_FRAME];
        
        _loginView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _loginView.autoresizesSubviews = YES;
        self.usernameField = [self textFieldWithPassword:NO placeholder:@" Enter User Name" origin:CGPointMake(0,20) icon:[[DkTImageCache sharedCache] imageNamed:@"user" color:[UIColor lightGrayColor]]];
        self.usernameField.helpText = @"PACER username";
        self.usernameField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        CGPoint nextOrigin = CGPointMake(0, CGRectGetMaxY(self.usernameField.frame)+self.usernameField.frame.size.height*.9);
        
        self.passwordField = [self textFieldWithPassword:YES placeholder:@" Enter Password" origin:nextOrigin icon:[[DkTImageCache sharedCache] imageNamed:@"lock" color:[UIColor lightGrayColor]]];
        self.passwordField.helpText = @"PACER password";
        self.passwordField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        nextOrigin = CGPointMake(0, CGRectGetMaxY(self.passwordField.frame)+self.passwordField.frame.size.height*.9);
        
        self.clientField = [self textFieldWithPassword:NO placeholder:@" Enter Client (optional)" origin:nextOrigin icon:[[DkTImageCache sharedCache] imageNamed:@"client" color:[UIColor lightGrayColor]]];
        self.clientField.helpText = @"Enter Client field (optional).";
        self.clientField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        
        [_loginView addSubview:self.usernameField];
        [_loginView addSubview:self.passwordField];
        [_loginView addSubview:self.clientField];
        
        
        self.dismissKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
        self.dismissKeyboardTap.cancelsTouchesInView = FALSE;
        [self.view addGestureRecognizer:self.dismissKeyboardTap];
        
    }
    
    return _loginView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(DkTTextField *) textFieldWithPassword:(BOOL)password placeholder:(NSString *)placeholder origin:(CGPoint)origin icon:(UIImage *)icon
{
    CGRect fr = LOGIN_FRAME;
    DkTTextField *textField = [[DkTTextField alloc] initWithFrame:CGRectMake(0,0,fr.size.width, 32)];
    textField.placeholder = placeholder;
    textField.clearsOnBeginEditing = YES;
    textField.secureTextEntry = password;
    CGRect frame = textField.frame;
    frame.origin = origin;
    textField.frame = frame;
    textField.delegate = self;
    textField.backgroundColor = [UIColor inactiveColor];
    textField.layer.cornerRadius = 5.0;
    textField.font = [UIFont fontWithName:kLightFont size:12];
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.returnKeyType = UIReturnKeyDone;
    
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
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        if(success)
        {
            
            _status = DkTLoggedIn;
            if(!self.modal) [self toggleContentView:DkTLoggedInPanelVisible];
            self.recentSessions = [self getRecentSessions];
            if(_usersView) [self.usersView reloadData];
            
            
            if(!self.modal) [((DkTSidePanelController *)self.parentViewController) resignWithCompletion:^(BOOL finished) {
                
                self.loggedInView = nil;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccessful" object:nil];
                
            }];
            
            else
            {
                if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) [self.parentViewController dismissPopupViewControllerWithanimationType:MJPopupViewAnimationSlideBottomBottom];
                
                else
                {
                    UIViewController *dvc = [UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
                    [dvc dismissViewControllerAnimated:YES completion:nil];
                }
            }
            
            
        }
        
        else
        {
            
            _status = DkTLoggedOut;
            
            DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Login Error" andMessage:@"Error logging into PACER. Check username and password?"];
            
            [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                
                [alertView dismissAnimated:YES];
                
            }];
            
            [alertView show];
            
        }

    });
    
}

-(UIButton *) loginButton
{
    if(_loginButton == nil)
    {
        NSArray *colors = @[[UIColor activeColor], [UIColor inactiveColor]];
        _loginButton = [FSButton buttonWithIcon:kLoginButtonImage colors:colors title:@"Login" actionBlock:^{
            
            if(_selectedSession != nil && self.usersView.superview)
            {
                if ([[PACERClient sharedClient] checkNetworkStatusWithAlert:YES])
                {
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    hud.color = [UIColor clearColor];
                    [[PACERClient sharedClient] loginForSession:_selectedSession sender:self];
                }
            }
            else if(self.usernameField.text.length < 1)
            {
                DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Input Error" andMessage:@"Please enter a username."];
                
                [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                    
                    [alertView dismissAnimated:YES];
                    
                }];
                
                [alertView show];
            }
            
            else if(self.passwordField.text.length < 1)
            {
                DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Input Error" andMessage:@"Please enter a password."];
                
                [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                    
                    [alertView dismissAnimated:YES];
                    
                }];
                
                [alertView show];
            }
            
            else if ([[PACERClient sharedClient] checkNetworkStatusWithAlert:YES])
            {
                DkTUser *newUser = [[DkTUser alloc] init];
                newUser.username = self.usernameField.text;
                newUser.password = self.passwordField.text;
                DkTSession *session = [[DkTSession alloc] init];
                session.user = newUser;
                session.client = (self.clientField.text.length > 0) ? self.clientField.text : @"";
                [[PACERClient sharedClient] loginForSession:session sender:self];
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.color = [UIColor clearColor];
            }
            
        }];
        
        _loginButton.titleLabel.font = [UIFont fontWithName:kMainFont size:16];
        _loginButton.layer.cornerRadius = 5.0;
        
        CGFloat width = 120;
        _loginButton.frame = CGRectMake(self.loginView.center.x - width/2., CGRectGetMaxY(self.loginView.frame)+10-(self.modal*10), width, 50-(self.modal*5));
        _loginButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _loginButton.imageView.transform = CGAffineTransformMakeScale(.5, .5);
        _loginButton.helpText = @"Login to PACER";
        
    }
    
    return _loginButton;
}


-(UIButton *) logoutButton
{
    if(_logoutButton == nil)
    {
        NSArray *colors = @[[UIColor inactiveColor], [UIColor activeColor]];
        _logoutButton = [FSButton buttonWithIcon:[UIImage imageNamed:@"unlock"] colors:colors title:@"Logout" actionBlock:^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"forceLogout" object:nil];
            [self toggleContentView:DkTLoginPanelVisible];
            
        }];
        
        _logoutButton.titleLabel.font = [UIFont fontWithName:kMainFont size:16];
        _logoutButton.layer.cornerRadius = 5.0;
        
        _logoutButton.frame = self.loginButton.frame;
        //_logoutButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _logoutButton.imageView.transform = CGAffineTransformMakeScale(.5, .5);
        _logoutButton.helpText = @"Logout user / client.";
        
    }
    
    return _logoutButton;
}

-(void) toggleUserView:(BOOL)visible
{
    
    if(visible)
    {
        [self toggleContentView:DkTRecentPanelVisible];
    }
        
    else
    {
        if (self.status == DkTLoggedIn) [self toggleContentView:DkTLoggedInPanelVisible];
        
        else [self toggleContentView:DkTLoginPanelVisible];
        
    }
        
    


}

-(NSArray *) getRecentSessions
{
    NSMutableArray *recentSessions = [NSMutableArray array];
    NSArray *sessions = [[DkTSessionManager sharedManager] sessions];
    
    int max = MIN(sessions.count, 4);
    int i;
    
    for(i = 0; i < max; i++)
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
        
        self.recentSessions = [self getRecentSessions];
        
        CGRect frame = LOGIN_FRAME;
        frame.size.height = _usersView.rowHeight * MAX(self.recentSessions.count,1);
        _usersView.frame = frame;
        _usersView.dataSource = self;
        _usersView.delegate = self;
        _usersView.scrollEnabled = YES;
        _usersView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _usersView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _usersView.scrollEnabled = NO;
        
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor inactiveColor];
        [_usersView setBackgroundView:backgroundView];
        _usersView.clipsToBounds = YES;
        _usersView.layer.cornerRadius = 5.0;
        
        IOS7(_usersView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);,  );
    }
    
    return _usersView;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        cell.contentView.helpText = @"Select a recent user/client and touch the Login button.";
        cell.textLabel.font = [UIFont fontWithName:kLightFont size:16];
        cell.textLabel.backgroundColor = [UIColor inactiveColor];
        cell.textLabel.textColor = [UIColor darkerTextColor];
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
        cell.contentView.backgroundColor =  [UIColor inactiveColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    
    else
    {
        DkTSession *session = [self.recentSessions objectAtIndex:indexPath.row];
        cell.contentView.backgroundColor =  [UIColor inactiveColor];
        
        cell.imageView.image = [kUserImage imageWithColor:[UIColor activeColor]];
        cell.imageView.transform = CGAffineTransformMakeScale(.5, .5);
        cell.textLabel.text = session.user.username;
        cell.detailTextLabel.text = (session.client.length > 0) ? session.client : nil;
        cell.detailTextLabel.textColor = [UIColor activeColor];
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

-(void)setModal:(BOOL)modal
{
    _modal = modal;
    self.loginButton = nil;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.recentSessions.count > 0)  _selectedSession = [self.recentSessions objectAtIndex:indexPath.row];
}

-(void) handleTap:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"forceLogout" object:nil];
    [self toggleContentView:DkTLoginPanelVisible];
}

-(void) dismissKeyboard:(id)sender
{
    [self.loginView endEditing:YES];
}


-(UIView *) loggedInView
{
    if(_loggedInView == nil)
    {
        CGRect frame = CGRectInset(LOGIN_FRAME,10,40);
        frame.origin.y += PAD_OR_POD(15, 10);
        _loggedInView = [[UIView alloc] initWithFrame:frame];
        _loggedInView.backgroundColor = [UIColor activeColor];
        _loggedInView.layer.cornerRadius = 5.0;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.text = @"Logged In";
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:kMainFont size:15];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor inactiveColor];
        [label sizeToFit];
        label.frame = CGRectMake(0, _loggedInView.frame.size.height*.1, _loggedInView.frame.size.width, label.frame.size.height);
        [_loggedInView addSubview:label];
        
        UIView *userLine = [[UIView alloc] initWithFrame:CGRectMake(15, _loggedInView.frame.size.height*.375, _loggedInView.frame.size.width, _loggedInView.frame.size.height*.2)];
        
        UIImageView *userImage = [[UIImageView alloc] initWithImage:[kUserImage imageWithColor:[UIColor inactiveColor]]];
        
        
        UILabel *loggedInAs = [[UILabel alloc] initWithFrame:CGRectZero];
        loggedInAs.text = [NSString stringWithFormat:@" %@",[DkTSession currentSession].user.username];
        loggedInAs.font = [UIFont fontWithName:kContrastFont size:12];
        loggedInAs.backgroundColor = [UIColor clearColor];
        loggedInAs.textColor = [UIColor inactiveColor];
        userImage.frame = CGRectMake(0, 0, 20, 20);
        loggedInAs.frame = CGRectMake(CGRectGetMaxX(userImage.frame), 0, 300, userImage.frame.size.height);
        [userLine addSubview:loggedInAs];
        [userLine addSubview:userImage];
        [loggedInAs sizeToFit];
        
        
        UIView *clientLine = [[UIView alloc] initWithFrame:CGRectMake(15, _loggedInView.frame.size.height*.575, _loggedInView.frame.size.width, _loggedInView.frame.size.height*.2)];
        
        UIImageView *clientImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"client"] imageWithColor:[UIColor inactiveColor]]];
        clientImage.frame = CGRectMake(0, 0, 20, 20);

        
        UILabel *client = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(clientImage.frame), 0, 100, clientImage.frame.size.height)];
        NSString *clientName = [DkTSession currentSession].client;
        client.text = (clientName.length == 0) ? @" (no client)" : [DkTSession currentSession].client;
        client.font = [UIFont fontWithName:kContrastFont size:12];
        client.textColor = [UIColor inactiveColor];
        client.backgroundColor = [UIColor clearColor];
        
        [clientLine addSubview:client];
        [clientLine addSubview:clientImage];
        
        //UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        //tap.numberOfTapsRequired = 1;
        //[_loggedInView addGestureRecognizer:tap];
       // _loggedInView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_loggedInView addSubview:userLine];
        [_loggedInView addSubview:clientLine];
    }
    
    return _loggedInView;
}


-(void) cookieDidExpireWithReveal:(BOOL)reveal
{
    [DkTSession nullifyCurrentSession];
    
    [self toggleContentView:DkTLoginPanelVisible];
     
    if(reveal)
    {
        [self.parentViewController.revealController showViewController:self.parentViewController animated:YES completion:^(BOOL finished) {
            
        }];
    }
    
}

-(void) viewWillAppear:(BOOL)animated {
   
    [self toggleContentView:self.panelChange];
    
}
-(void) forceLogout:(id)sender
{
    _status = DkTLoggedOut;
    self.panelChange = DkTLoginPanelVisible;
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

-(void) toggleContentView:(DkTPanelVisibility)visibility
{
    self.panelChange = DkTPanelVisibilityNone;
    
    if(self.currentPanel == visibility) return;
    
    if(visibility == DkTPanelVisibilityNone) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        for (UIView *subview in self.view.subviews) {
            
            if(![subview isKindOfClass:[MBProgressHUD class]]) [subview removeFromSuperview];
            
        }

        if(visibility == DkTLoginPanelVisible)
        {
            [self.view addSubview:self.loginView];
            [self.view addSubview:self.loginButton];
        }
        
        if(visibility == DkTRecentPanelVisible)
        {
            [self.view addSubview:self.usersView];
            [self.view addSubview:self.loginButton];
        }
        
        if(visibility == DkTLoggedInPanelVisible)
        {
            self.loggedInView = nil;
            [self.view addSubview:self.loggedInView];
            [self.view addSubview:self.logoutButton];
        }
        
        self.currentPanel = visibility;
        
        if(self.status == DkTLoggingIn)
        {
            [self displayLoggingIn];
        }
        
        [self.view setNeedsDisplay];
        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
        if(hud) [self.view bringSubviewToFront:hud];
        
   });
    
}

@end


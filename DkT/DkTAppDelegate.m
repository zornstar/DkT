//
//  DkTAppDelegate.m
//  DkTp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTAppDelegate.h"
#import "DkTDocumentManager.h"
#import "DkTRootViewController.h"
#import "DkTAlertView.h"
#import "PACERClient.h"
#import "DkTLoginViewController.h"
#import "DkTSessionManager.h"
#import "DkTSettings.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Utilities.h"

#define kDkTDateLastActiveKey @"DkTDateLastActive"

@implementation DkTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kDkTDateLastActiveKey];
    [self config];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    // Override point for customization after application launch.
   
    self.viewController = [[DkTRootViewController alloc] init];
    
    [DkTDocumentManager clearTempFiles];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    
    
    return YES;
}

-(void) config
{
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundColor:[UIColor activeColor]];
    NSDictionary *attributes = @{UITextAttributeTextColor:[UIColor inactiveColor]};
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes
                                                forState:UIControlStateNormal];
    [[UINavigationBar appearance] setTitleTextAttributes:attributes];
    [[UIToolbar appearance] setBackgroundColor:[UIColor activeColor]];
    [[UIToolbar appearance] setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance] setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];

    IOS7([[UIBarButtonItem appearance]
          setBackButtonBackgroundImage:[[UIImage alloc] init]
          forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];, );
    
    [[DkTAlertView appearance] setCornerRadius:5.0];
    [[DkTAlertView appearance] setTitleFont:[UIFont fontWithName:kMainFont size:15.]];
    [[DkTAlertView appearance] setMessageFont:[UIFont fontWithName:kLightFont size:11.]];
    [[DkTAlertView appearance] setButtonFont:[UIFont fontWithName:kLightFont size:11.]];
    [[DkTAlertView appearance] setButtonCornerRadius:5.0];
    [[DkTAlertView appearance] setViewBackgroundColor:[UIColor inactiveColorDark]];
    [[DkTAlertView appearance] setTitleColor:[UIColor darkerTextColor]];
    [[DkTAlertView appearance] setMessageColor:[UIColor darkerTextColor]];
    [[DkTAlertView appearance] setButtonColor:[UIColor inactiveColor]];
    
    IOS7([[UITableView appearance] setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];,  );
    IOS7(, [[UIBarButtonItem appearance] setTintColor:[UIColor activeColor]];);
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
         [[UITabBar appearance] setSelectedImageTintColor:[UIColor inactiveColor]];
         [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageOfColor:[UIColor activeColor] size:CGSizeMake(324/3., 50)]];
         [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
         [[UITabBarItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor : [UIColor darkerTextColor], UITextAttributeFont : [UIFont fontWithName:kMainFont size:10]} forState:UIControlStateNormal];
        [[UITabBarItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor : [UIColor lighterTextColor], UITextAttributeFont : [UIFont fontWithName:kMainFont size:10]} forState:UIControlStateSelected];
         [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    }
    
    
    [[UITabBar appearance] setBackgroundColor:[UIColor inactiveColor]];
    [[UIActivityIndicatorView appearance] setColor:[UIColor darkerTextColor]];
    [ZSHelpController set];
    ZSHelpController *helpController = [ZSHelpController sharedHelpController];
    helpController.targetView =  self.viewController.view;
    helpController.backgroundColor = [UIColor inactiveColor];
    helpController.position = ZSTopRight;
    helpController.icon = [kQuestionsImage imageWithColor:[UIColor activeColor]];
    [helpController setFont:kHelpFont.fontName withColor:[UIColor activeColor]];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kDkTDateLastActiveKey];
    [defaults synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSDate *time = [[NSUserDefaults standardUserDefaults] objectForKey:kDkTDateLastActiveKey];
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:time];
    
    if(timeInterval >= 900){ //15 minutes
     
        [[NSNotificationCenter defaultCenter] postNotificationName:@"forceLogout" object:nil];
        
        if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsAutoLoginKey] boolValue])
        {
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"autoLogin" object:nil];
            });
        }
        
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
   
}


@end

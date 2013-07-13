//
//  DkTAppDelegate.m
//  DkTp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTAppDelegate.h"
#import "DkTViewController.h"
#import "DkTDocumentManager.h"
#import "DkTRootViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "UIImage+Utilities.h"
#import "ZSHelpController.h"

@implementation DkTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [self config];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        
    } else {
        self.viewController = [[DkTRootViewController alloc] init];
    }
    
    //background
    [DkTDocumentManager clearTempFiles];
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

-(void) config
{
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundColor:kActiveColor];
    
    [[UIToolbar appearance] setBackgroundColor:kActiveColor];
    
    [ZSHelpController set];
    
    ZSHelpController *helpController = [ZSHelpController sharedHelpController];
    helpController.targetView =  self.viewController.view;
    helpController.backgroundColor = kInactiveColor;
    helpController.position = ZSTopRight;
    helpController.icon = [kQuestionsImage imageWithColor:kActiveColor];
    [helpController setFont:kHelpFont.fontName withColor:kActiveColor];
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end

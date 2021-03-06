
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSettings.h"
#import "PACERClient.h"

NSString* const DkTSettingsSecondaryClientEnabledKey = @"DkTSettingsSecondaryClientEnabledKey";
NSString* const DkTSettingsAutoLoginKey = @"DkTSettingsAutoLoginKey";
NSString* const DkTSettingsAddTOCKey = @"DkTSettingsTOCKey";
NSString* const DkTSettingsCacheRecentKey = @"DkTSettingsCacheRecentKey";
NSString* const DkTSettingsPrintStampKey = @"DkTSettingsPrintStampKey";
NSString* const DkTSettingsMostRecentKey = @"DkTSettingsMostRecentFirst";
NSString* const DkTVersionNumber = @"2.0";

@implementation DkTSettings

+ (id)sharedSettings
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[DkTSettings alloc] init];
    });
    return sharedInstance;
}

-(id) valueForKey:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

-(void) setValue:(id)value forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    
}

-(void) setBoolValue:(BOOL)value forKey:(NSString *)key
{
    NSNumber *boolValue = [NSNumber numberWithBool:value];
    
    [[NSUserDefaults standardUserDefaults] setValue:boolValue forKey:key];
}


@end

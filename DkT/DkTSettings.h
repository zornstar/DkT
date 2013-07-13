//
//  DkTSettings.h
//  DkTp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const DkTSettingsEnabledKey;
extern NSString* const DkTSettingsReceiptKey;
extern NSString* const DkTSettingsQuickLoginKey;

@interface DkTSettings : NSObject

+(id) sharedSettings;
-(id) valueForKey:(NSString *)key;
-(void) setValue:(id)value forKey:(NSString *)key;
-(void) setBoolValue:(BOOL)value forKey:(NSString *)key;

@end

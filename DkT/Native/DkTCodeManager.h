
//
//  Created by Matthew Zorn on 7/15/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, DkTCodeType) {
    DkTCodeTypeNone = 0,
    DkTCodeTypeDistrictCourt = (1 << 0),
    DkTCodeTypeAppellateCourt = (1 << 1),
    DkTCodeTypeBankruptcyCourt = (1 << 2),
    DkTCodeTypeBankruptcyAppellateCourt = (1 << 3),
    DkTCodeTypeRegion = (1 << 4),
};


extern NSString* const DkTCodeSearchDisplayKey;
extern NSString* const DkTCodeBluebookKey;
NSString* const DkTCodePACERSearchKey;
NSString* const DkTCodePACERDisplayKey;

@interface DkTCodeManager : NSObject

/**
 Return singleton object
 */
+(id) sharedManager;

/**
 Return an array of values that matches a key and bitmask type variable
 */
+(NSArray *) valuesForKey:(NSString *)key types:(DkTCodeType)type;
+(NSArray *) valuesForKey:(NSString *)key type:(DkTCodeType)type;

/**
 Convert a code from one format to another (e.g., bluebook --> pacer)
 */
+(NSString *)translateCode:(NSString *)code inputFormat:(NSString *)input outputFormat:(NSString *)output;
+(NSString *)translateCode:(NSString *)code inputFormat:(NSString *)input outputFormat:(NSString *)output type:(DkTCodeType)type;
@end

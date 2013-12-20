//
//  DkTCodeManager.h
//  DkT
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
+(id) sharedManager;
+(NSArray *) valuesForKey:(NSString *)key types:(DkTCodeType)type;
+(NSArray *) valuesForKey:(NSString *)key type:(DkTCodeType)type;
+(NSString *)translateCode:(NSString *)code inputFormat:(NSString *)input outputFormat:(NSString *)output;
+(NSString *)translateCode:(NSString *)code inputFormat:(NSString *)input outputFormat:(NSString *)output type:(DkTCodeType)type;
@end

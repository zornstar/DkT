
//
//  Created by Matthew Zorn on 5/28/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DkTDocket, DkTDocketEntry;

@interface PACERParser : NSObject

/**
 parseAppellateDocket
 - parse an appellate docket, return an array of DkTDocketEntry */

+(NSArray *)parseAppellateDocket:(DkTDocket *)docket html:(NSData *)html;

/**
 parseAppellateDocket
 - parse an appellate multi-document entry, return an array of DkTAttachment (subclass of DkTDkTEntry) */

+(NSArray *)parseAppellateMultiDoc:(DkTDocketEntry *)entry html:(NSData *)html;

/**
 parseForNextPage
 - parse for next page on a pacer search results (i.e., next link), return link */

+(NSString *)parseForNextPage:(NSData *)html;

/**
 parseForNextPage
 - parse search result page into array of DkTDockets */

+(NSString *) loginToken:(NSData *)html;
+(NSMutableArray *) parseSearchResults:(NSData *)html;
+(NSString *) pdfURLForDownloadDocument:(NSData *)data;
+(NSArray *) parseDocket:(DkTDocket *)docket html:(NSData *)data;
+(NSString *)parseMore:(NSData *)data docket:(DkTDocket *)docket;
+(NSString *)parseDocketSheet:(NSData *)html courtType:(PACERCourtType)type;
+ (BOOL) parseLogin:(NSData *)html; +(BOOL) isLoggedIn:(NSData *)html;
+(NSArray *)parseMultiDoc:(DkTDocketEntry *)entry html:(NSData *)html;
+(void) parseAppellateCaseSelectionPage:(NSData *)html withDocket:(DkTDocket *)docket completion:(void (^)(NSString *cs_caseid))completion;
@end

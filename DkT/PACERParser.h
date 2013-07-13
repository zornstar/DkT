//
//  PACERParser.h
//  DkTp
//
//  Created by Matthew Zorn on 5/28/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DkTDocket;

@interface PACERParser : NSObject

+(NSArray *) parseAppellateDocket:(NSData *)xml;
+(NSString *)parseForNextPage:(NSData *)html;
+(NSMutableArray *) parseSearchResults:(NSData *)html;
+(NSArray *)parseDocumentPage:(NSData *)html;
+(float) parseHtmlStringForCost:(NSString *)htmlString;
+(NSString *) pdfURLForDownloadDocument:(NSData *)data;
+(NSArray *) parseDocket:(DkTDocket *)docket html:(NSData *)data;
+(NSString *)parseDocketSheet:(NSData *)html courtType:(PACERCourtType)type;

+(BOOL) parseLogin:(NSData *)html; +(BOOL) isLoggedIn:(NSData *)html;

@end

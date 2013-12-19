//
//  RECAPClient.h
//  DkT
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "AFHTTPClient.h"
#import "PACERClient.h"

#define kRECAPBaseURL @"http://recapextension.org/"
#define kRECAPUploadURL @"upload/"
#define kQueryURL @"http://recapextension.org/recap/query/"
#define kQueryCasesURL @"query_cases/"
#define kAddDocMetaURL @"adddocmeta/"

extern NSString* const DkTFileLinkKey;

typedef void (^DkTQueryBlock)(id entry, id json);

@class RECAPClient, DkTDocketEntry;

@protocol RECAPClientProtocol <NSObject>

-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path;

@optional

-(void) didDownloadDocketSheet:(NSData *)docketSheet;
-(void) queryForDocketEntry:(DkTDocketEntry *)entry json:(NSDictionary *)json;

@end

@interface RECAPClient : AFHTTPClient

+(id) sharedClient;
+(PACERClient *) pacerClient;

-(void) getDocument:(DkTDocketEntry *)entry sender:(id<PACERClientProtocol>)sender;
-(void) uploadCasePDF:(NSData *)data docketEntry:(DkTDocketEntry *)entry;
-(void) isDocketEntryRECAPPED:(DkTDocketEntry *)entry completion:(DkTQueryBlock)blk;
-(void) uploadDocket:(NSData *)data docket:(DkTDocket *)docket;
-(void) uploadDocMeta:(DkTDocketEntry *)entry;

@end

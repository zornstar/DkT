//
//  RECAPClient.h
//  DkT
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "AFHTTPClient.h"
#import "PACERClient.h"

#define kRECAPBaseURL @"http://dev.recapextension.org/DkT/"
#define kRECAPUploadURL @"upload/"
#define kQueryURL @"http://www.recapxtension.org/DkT/query/"
#define kQueryCasesURL @"query_cases/"
#define kAddDocMetaURL @"adddocmeta/"
#define kSearchURL

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
-(void) getDocket:(DkTDocket *)docket sender:(UIViewController<PACERClientProtocol>*)sender;
-(void) getDocument:(DkTDocketEntry *)entry sender:(UIViewController<PACERClientProtocol>*)sender;
-(void) uploadCasePDF:(NSData *)data court:(NSString *)court url:(NSString *)url;
-(void) uploadDocket:(NSData *)data court:(NSString *)court caseNumber:(NSString *)casenum;
-(void) isDocketEntryRECAPPED:(DkTDocketEntry *)entry sender:(UIViewController<RECAPClientProtocol>*)sender;
-(void) isDocketEntryRECAPPED:(DkTDocketEntry *)entry completion:(DkTQueryBlock)blk;

-(void) uploadDocMeta:(DkTDocketEntry *)entry;

@end

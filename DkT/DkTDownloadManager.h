//
//  DkTDownloader.h
//  DkTp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFHTTPClient, DkTDocketEntry, DkTDocket;

@protocol DkTDownloadManagerProtocol <NSObject>

-(void) didFinishDownload:(DkTDocket *)docket;
-(void) didFinishOperationNumber:(NSInteger)opNum total:(NSInteger)total;

@end

@interface DkTDownloadManager : NSObject

+(id) sharedManager;
+(void) batchDownload:(DkTDocket *)docket entries:(NSArray *)docketEntries sender:(UIViewController<DkTDownloadManagerProtocol>*)sender;
+(void) terminate;

@end

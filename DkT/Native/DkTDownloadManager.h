
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PACERClient.h"
#import "DkTDownload.h"
#import "DkTDocumentsViewController.h"

@class /*SecondaryClient,*/ DkTDocketEntry, DkTDocket, DkTDownloadManager;

@protocol DkTDownloadManagerProtocol <NSObject>

@optional
-(void) downloadManager:(DkTDownloadManager *)manager didFinishDownload:(DkTDownload *)entry;
-(void) downloadManager:(DkTDownloadManager *)manager didHandleError:(DkTDownload *)entry;
-(void) downloadManager:(DkTDownloadManager *)manager didHandleSealedDocument:(DkTDownload *)entry;
-(void) downloadManager:(DkTDownloadManager *)manager didHandleEntries:(NSArray *)entries entry:(DkTDownload *)entry;

@end

@interface DkTDownloadManager : NSObject <PACERClientProtocol>

+(id) sharedManager;
//+(SecondaryClient *)secondaryClient;
+(PACERClient *)pacerClient;
+(void) batchDownload:(DkTDocket *)docket entries:(NSArray *)docketEntries sender:(UIViewController<DkTDownloadManagerProtocol>*)sender;
+(void) batchDownload:(DkTDownload *)download docket:(DkTDocket *)docket sender:(UIViewController<DkTDownloadManagerProtocol>*)sender;
+(void) terminate;

@property (nonatomic, strong) PACERClient *pacerClient;
//@property (nonatomic, strong) SecondaryClient *secondaryClient;
@property (weak) id<DkTDownloadManagerProtocol>delegate;
@property (nonatomic, strong) DkTDownload *batchDownload;

@end

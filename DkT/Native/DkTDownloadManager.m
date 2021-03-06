
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDownloadManager.h"
#import "DkTDocumentManager.h"
#import "DkTDocketEntry.h"
#import "DkTDocket.h"
#import "AFDownloadRequestOperation.h"
#import "PACERParser.h"
#import "DkTSettings.h"
#import "PACERClient.h"
//#import "SecondaryClient.h"

#define kSecondaryClientBaseURL @""
#define kPACERBaseURL @"https://pcl.uscourts.gov/"

@interface DkTDownloadManager ()

@end

@implementation DkTDownloadManager

+(id)sharedManager
{
    static dispatch_once_t pred;
    static DkTDownloadManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[DkTDownloadManager alloc] init];
    });
    return sharedInstance;
}

-(PACERClient *)pacerClient
{
    if(_pacerClient == nil)
    {
        _pacerClient = [[PACERClient alloc] init];
    }
    
    return _pacerClient;
}

/*
-(SecondaryClient *)secondaryClient
{
    if(_secondaryClient == nil)
    {
        _secondaryClient = [[SecondaryClient alloc] init];
    }
    
    return _secondaryClient;
}*/

+(PACERClient *)pacerClient
{
    return [[DkTDownloadManager sharedManager] pacerClient];
}

/*
+(SecondaryClient *)secondaryClient
{
    return [[DkTDownloadManager sharedManager] secondaryClient];
}*/

+(void) batchDownload:(DkTDownload *)download docket:(DkTDocket *)docket sender:(UIViewController<DkTDownloadManagerProtocol> *)sender
{
    
    DkTDownloadManager *mgr = [DkTDownloadManager sharedManager];
    
    for(DkTDownload *d in download.children)
    {
        if([d.entry.urls objectForKey:LocalURLKey])
        {
            if([mgr.delegate respondsToSelector:@selector(downloadManager:didFinishDownload:)] && sender)
            {
                [mgr.delegate downloadManager:mgr didFinishDownload:d];
            }
            
            continue;
        }
        
        /*
        if([[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryClientEnabledKey] && [download.entry.urls objectForKey:DkTURLKey])
        {
            [[DkTDownloadManager secondaryClient] getDocument:d.entry sender:mgr];
        }*/
        
        //else
        [[DkTDownloadManager pacerClient] retrieveDocument:download.entry sender:mgr docket:docket];
    }
}

+(void) batchDownload:(DkTDocket *)docket entries:(NSArray *)docketEntries sender:(UIViewController<DkTDownloadManagerProtocol>*)sender
{
    
    DkTDownloadManager *mgr = [DkTDownloadManager sharedManager];
    
    for(DkTDocketEntry *entry in docketEntries)
    {
        if([entry.urls objectForKey:LocalURLKey])
        {
            DkTDownload *download = [mgr.batchDownload downloadForEntry:entry];
            download.status = DkTDownloadCompletionStatusComplete;
            
            continue;
        }
        
        /*
        if([[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryClientEnabledKey] && [entry.urls objectForKey:DkTURLKey])
        {
            [[DkTDownloadManager secondaryClient] getDocument:entry sender:mgr];
        }*/
           
        else [[DkTDownloadManager pacerClient] retrieveDocument:entry sender:mgr docket:docket];
    }
}


-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path
{
    [self didDownloadDocketEntry:entry atPath:path cost:YES];
}

-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path cost:(BOOL)paid
{
    DkTDownload *download = [self.batchDownload downloadForEntry:entry];
    [download setStatus:DkTDownloadCompletionStatusComplete];
    [DkTDocumentManager saveDocketEntry:entry atTempPath:path];
}

-(void) handleDocketEntryError:(DkTDocketEntry *)entry
{
    DkTDownload *download = [self.batchDownload downloadForEntry:entry];
    [download setStatus:DkTDownloadCompletionStatusError];
   
}

-(void) handleSealedDocument:(DkTDocketEntry *)entry
{
    DkTDownload *download = [self.batchDownload downloadForEntry:entry];
    [download setStatus:DkTDownloadCompletionStatusError];
}

-(void) handleDocumentsFromDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry entries:(NSArray *)entries
{
    
    DkTDownload *d = [self.batchDownload downloadForEntry:entry];
    
    [d addEntries:entries completionBlock:^(DkTDownload *download, DkTDownloadCompletionStatus status) {
       
        download.parent.completedChildren++;
        
        NSInteger completed = download.parent.completedChildren;
        NSUInteger total = download.parent.children.count;

        if(completed == total) [download.parent updateCompletionStatus];
        
    }];
    
    [DkTDownloadManager batchDownload:docket entries:entries sender:nil];
    
}

+(void) terminate
{
    NSOperationQueue *queue = [[DkTDownloadManager sharedManager] pacerClient].operationQueue;
    for (NSOperation *op in queue.operations)
    {
        [op cancel];
    }
}

+ (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


@end


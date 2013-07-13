//
//  DkTDownloader.m
//  DkTp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDownloadManager.h"
#import "DkTDocketEntry.h"
#import "DkTDocket.h"
#import "AFDownloadRequestOperation.h"
#import "PACERParser.h"
#import "AFHTTPClient.h"

#define kDkTBaseURL @"http://dev.DkTextension.org/DkT/"
#define kPACERBaseURL @"https://pcl.uscourts.gov/"

@interface DkTDownloadManager ()

@property (nonatomic, strong) AFHTTPClient *downloadClient;

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

-(id) init
{
    if(self = [super init])
    {
        _downloadClient = [[AFHTTPClient alloc] init];
    }
    
    return self;
}

+(void) batchDownload:(DkTDocket *)docket entries:(NSArray *)docketEntries sender:(UIViewController<DkTDownloadManagerProtocol>*)sender
{
    NSString *docketPath = [docket folder];
    
    NSMutableArray *downloadOperations = [NSMutableArray array];
    
    for(DkTDocketEntry *entry in docketEntries)
    {
        NSString *courtLink = [entry courtLink];
        NSString *path = [entry link];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
        [request setHTTPMethod:@"POST"];
        NSString *urlenc = [entry urlEncodedParams];
        NSData *form = [urlenc dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:form];
        AFHTTPRequestOperation *getDocument = [[AFHTTPRequestOperation alloc] initWithRequest:request];
      
        
        [getDocument setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            
            NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            
            if([responseString rangeOfString:@"Document Selection Menu" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                //handle multidocument by batching
                
                
                
            }
            
            else {
                
                NSString *filePath = [docketPath stringByAppendingString:[entry fileName]];
                
                NSLog(@"%@", [operation.response.allHeaderFields description]);
                
                if ([[operation.response.allHeaderFields objectForKey:@"Content-Type"] isEqualToString:@"application/pdf"]) {
                    
                    NSData *data = responseObject;
                    
                    [data writeToFile:filePath atomically:YES];
                    
                    
                }
                
                else {
                    
                    NSString *pdfLink = [PACERParser pdfURLForDownloadDocument:responseObject];
                    NSString *pdfPath = [courtLink stringByAppendingString:pdfLink];
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pdfPath]];
                    
                    AFDownloadRequestOperation *downloadOperation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:filePath shouldResume:NO];
                    
                    [downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                        
                        
                        
                    }
                     
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                 
                    }];
                    
                    [[DkTDownloadManager sharedManager] enqueueHTTPRequestOperation:downloadOperation];
                }
                
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"%@", [error description]);
        }];
        
        [downloadOperations addObject:getDocument];
    }
    
    [[DkTDownloadManager sharedManager] enqueueBatchOfHTTPRequestOperations:downloadOperations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
        if([sender respondsToSelector:@selector(didFinishOperationNumber:total:)])
        {
            [sender didFinishOperationNumber:numberOfFinishedOperations total:totalNumberOfOperations];
        }
        
    } completionBlock:^(NSArray *operations) {
        

        
    }];
}

+(void)downloadDocket:(DkTDocket *)docket docketItems:(NSArray *)items filePath:(NSString *)filePath
{
    [[[DkTDownloadManager sharedManager] downloadClient].operationQueue setMaxConcurrentOperationCount:4];
    
    //get folder
    //if not exists create
    //check if filepath exists for document
    //if not download
    //next file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tempDirPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSDate date] description]];
    NSError *error = nil;
    BOOL isDir;
    
    if(![fileManager fileExistsAtPath:tempDirPath isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:tempDirPath withIntermediateDirectories:YES attributes:nil error:&error])
            NSLog(@"Error: Create folder failed");
    
    NSBlockOperation *combineOperation = [NSBlockOperation blockOperationWithBlock:^{
        [DkTDownloadManager joinDocket:docket filePath:tempDirPath toFilePath:filePath];
    }];
    
    //recursion
    [self downloadItems:items toPath:tempDirPath blockOperation:combineOperation counter:@""];
    
    [[[DkTDownloadManager sharedManager] operationQueue] addOperation:combineOperation];
}

+(void) downloadItems:(NSArray *)items toPath:(NSString *)path blockOperation:(NSOperation *)blockOp counter:(NSString *)counterString
{
    for (int i = 0; i < items.count; ++i) {
        
        DkTDocketEntry *entry = [items objectAtIndex:i];
        
        NSString *tempFilePath = [NSString stringWithFormat:@"%@/%d - %@.pdf", path, entry.entry,entry.name];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:entry.link]];
            
        AFDownloadRequestOperation *downloadOperation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:tempFilePath shouldResume:YES];
        
        
        [[DkTDownloadManager sharedManager] enqueueHTTPRequestOperation:downloadOperation];
        
        [blockOp addDependency:downloadOperation];
            
            [downloadOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                
                
                float percentDone = ((float)totalBytesRead) / totalBytesExpectedToRead;
                
            }];
            
        } //end PDFBlock
    
}

+(void) terminate
{
    NSOperationQueue *queue = [[DkTDownloadManager sharedManager] downloadClient].operationQueue;
    for (NSOperation *op in queue.operations)
    {
        [op cancel];
    }
}
     
+(NSString *)joinDocket:(DkTDocket *)docket filePath:(NSString *)directory toFilePath:(NSString *)filePath {
    
    // File paths
    
    NSArray *tempFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL];
    CFURLRef pdfURLOutput =(__bridge_retained CFURLRef) [[NSURL alloc] initFileURLWithPath:(NSString *)filePath];//(CFURLRef)
    CGContextRef context = CGPDFContextCreateWithURL(pdfURLOutput, NULL, NULL);
    
    //insert docket page
    for(NSString *fileName in tempFiles)
    {
        NSString *fullTempPath = [directory stringByAppendingPathComponent:fileName];
        
        CFURLRef pdfURL = (__bridge_retained CFURLRef)[[NSURL alloc] initFileURLWithPath:(NSString *)fullTempPath];
        
        CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithURL((CFURLRef) pdfURL);
        
        NSInteger numberOfPages = CGPDFDocumentGetNumberOfPages(pdfRef);
        
        CGPDFPageRef page;
        CGRect mediaBox;
        
        //insert title page
        for (int i=1; i<=numberOfPages; i++) {
            page = CGPDFDocumentGetPage(pdfRef, i);
            mediaBox = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
            CGContextBeginPage(context, &mediaBox);
            CGContextDrawPDFPage(context, page);
            CGContextEndPage(context);
        }
        
        CFRelease(pdfURL);
        CGPDFDocumentRelease(pdfRef);
    }
    
    
    CGContextRelease(context);
    CFRelease(pdfURLOutput);
    
    //Clear the temp directory
    [DkTDownloadManager clearCache:directory];
    id delegate = [[DkTDownloadManager sharedManager] delegate];
    
    if([delegate respondsToSelector:@selector(didFinishDownload:)])
    {
        [delegate didFinishDownload:docket];
    }
    
    return filePath;
}

+(void) clearCache:(NSString *)filePath
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError * error;
    NSArray * cacheFiles = [fileManager contentsOfDirectoryAtPath:filePath error:&error];
    
    for(NSString * file in cacheFiles)
    {
        error=nil;
        NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:file ];
        NSLog(@"filePath to remove = %@",filePath);
        
        BOOL removed =[fileManager removeItemAtPath:filePath error:&error];
        if(removed ==NO)
        {
            NSLog(@"removed ==NO");
        }
        if(error)
        {
            NSLog(@"%@", [error description]);
        }
    }
    
}

+ (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}
             
@end


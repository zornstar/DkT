//
//  RECAPClient.m
//  DkT
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "RECAPClient.h"
#import "PACERClient.h"

#import "DkTAlertView.h"
#import "AFJSONRequestOperation.h"
#import "AFHTTPRequestOperation.h"
#import "AFDownloadRequestOperation.h"
#import "DkTDocketEntry.h"
#import "DkTDocket.h"
#import "MBProgressHUD.h"
#import "DkTDocumentManager.h"
#import "DkTSettings.h"

NSString* const RECAPFileLinkKey = @"filename";

@implementation RECAPClient

+ (id)sharedClient
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[RECAPClient alloc] init];
    });
    return sharedInstance;
}

+(PACERClient *)pacerClient
{
    return [PACERClient sharedClient];
}

-(id) init
{
    if(self = [super initWithBaseURL:[NSURL URLWithString:kRECAPBaseURL]])
    {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
        self.parameterEncoding = AFJSONParameterEncoding;
    }
    
    return self;
}

-(void) getDocument:(DkTDocketEntry *)entry sender:(UIViewController<PACERClientProtocol>*)sender
{
    NSString *pdfPath = [entry.urls objectForKey:DkTURLKey];
    NSLog(@"%@", pdfPath);
    
    if([[pdfPath pathExtension] isEqualToString:@"pdf"])
    {
        NSString *tempDir = NSTemporaryDirectory();
        
        NSString *tempFilePath = [tempDir stringByAppendingPathComponent:[entry fileName]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pdfPath]];
        
        //if file exists at temp path, then just get it from temppath
        if([[NSFileManager defaultManager] fileExistsAtPath:tempFilePath])
        {
            if([sender respondsToSelector:@selector(didDownloadDocketEntry:atPath:cost:)])
            {
                [sender didDownloadDocketEntry:entry atPath:tempFilePath cost:NO];
                
            }
            
            return;
        }
        
        AFDownloadRequestOperation *downloadOperation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:tempFilePath shouldResume:NO];
        
        [downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            if([sender respondsToSelector:@selector(didDownloadDocketEntry:atPath:cost:)])
            {
                NSLog(@"%@", tempFilePath);
                [sender didDownloadDocketEntry:entry atPath:tempFilePath cost:NO];
                
            }
            
            
            
            
        }
         
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            DkTAlertView *alert = [[DkTAlertView alloc] initWithTitle:@"Error" andMessage:@"Error downloading document."];
            
            [alert addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
                
                [alertView dismissAnimated:YES];
            }];
            
            [alert show];
            
        }];
        
        [self enqueueHTTPRequestOperation:downloadOperation];
        
    }
    
    else
    {
        DkTAlertView *alert = [[DkTAlertView alloc] initWithTitle:@"Error" andMessage:@"Error downloading document."];
        
        [alert addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
           
            [alertView dismissAnimated:YES];
        }];
        
        [alert show];
    }
        
   
    
}


-(void) isDocketEntryRECAPPED:(DkTDocketEntry *)entry completion:(DkTQueryBlock)blk
{
    if( (entry.docket.court == nil) || (entry.link == nil) ) return;
    
    if( ![[[DkTSettings sharedSettings] valueForKey:DkTSettingsRECAPEnabledKey] boolValue]) return;
    
    if(blk) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kQueryURL]];
        
        [request setHTTPMethod:@"POST"];
     
        NSString *body = @"json=";
        
        
        NSDictionary *params = @{@"court":[entry shortCourt],
                                 @"urls":@[[entry linkPath]]};
        NSError *error;
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //json encoding escapes forward slashes
        jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        
        body = [body stringByAppendingString:jsonString];
        
        
        
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        
        AFJSONRequestOperation *queryOperation = [[AFJSONRequestOperation alloc] initWithRequest:request];
        
        [queryOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            
            if(responseObject) blk(entry, (NSDictionary *)responseObject);
    
            else blk(entry, nil);
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            blk(entry, nil);
        }];
        
        
        [self enqueueHTTPRequestOperation:queryOperation];
    }
    
    
}


-(void) uploadDocket:(NSData *)data docket:(DkTDocket *)docket
{
    NSDictionary *params = @{@"mimetype":@"text/html; charset=UTF-8",
                             @"court":[docket shortCourt],
                             @"casenum":[docket cs_caseid]};
    NSMutableURLRequest *request = [self multipartFormRequestWithMethod:@"POST" path:@"http://dev.recapextension.org/recap/upload/" parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        [formData appendPartWithFileData:data
                                    name:@"data"
                                fileName:@"DktRpt.html"
                                mimeType:@"text/html; charset=UTF-8"];
    }];
    
    [request setHTTPMethod:@"POST"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success!");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"doh!");
    }];
    [self enqueueHTTPRequestOperation:operation];
}

-(void) uploadCasePDF:(NSData *)data docketEntry:(DkTDocketEntry *)entry
{
    NSString *docID = [entry docID];
    
    if(docID != nil)
    {
        NSDictionary *params = @{@"mimetype":@"application/pdf",
                                 @"court":[entry shortCourt],
                                 @"url":[NSString stringWithFormat:@"/doc1/%@", docID]};
        NSMutableURLRequest *request = [self multipartFormRequestWithMethod:@"POST" path:@"http://recapextension.org/recap/upload/" parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            [formData appendPartWithFileData:data
                                        name:@"data"
                                    fileName:[NSString stringWithFormat:@"%@.pdf", [entry docID]]
                                    mimeType:@"application/pdf"];
        }];
        
        [request setHTTPMethod:@"POST"];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"success!");
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"doh!");
        }];
        [self enqueueHTTPRequestOperation:operation];
    }
   
}

-(void) uploadDocMeta:(DkTDocketEntry *)entry
{
    NSString *docID = entry.docID;
    
    if(docID)
    {
        NSDictionary *params = @{@"docid":docID, @"court":entry.docket.court, @"add_case_info":@"true"};
        
        
        [self postPath:@"adddocmeta" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    }
    

}



@end

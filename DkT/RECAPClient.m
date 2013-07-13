//
//  RECAPClient.m
//  DkT
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "RECAPClient.h"
#import "PACERClient.h"

#import "AFJSONRequestOperation.h"
#import "AFHTTPRequestOperation.h"
#import "AFDownloadRequestOperation.h"
#import "DkTDocketEntry.h"
#import "DkTDocket.h"
#import "MBProgressHUD.h"
#import "DkTDocumentManager.h"

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

-(void) getDocketEntry:(DkTDocketEntry *)entry sender:(id<PACERClientProtocol>)sender
{
    // metadata for a PDF file, should have the following properties:
    //    filemeta.mimetype ('application/pdf')
    //    filemeta.court ('cacd')
    //    filemeta.name ('1234567890.pdf')
    //    filemeta.url ('/doc1/1234567890')
    
    [RECAPClient pacerClient];
}

-(void) getDocument:(DkTDocketEntry *)entry sender:(UIViewController<PACERClientProtocol>*)sender
{
    NSString *pdfPath = [entry.urls objectForKey:DkTURLKey];
    NSLog(@"%@", pdfPath);
    
    if([[pdfPath pathExtension] isEqualToString:@"pdf"])
    {
        //fix
        NSString *tempDir = NSTemporaryDirectory();
        
        NSString *tempFilePath = [tempDir stringByAppendingPathComponent:[entry fileName]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pdfPath]];
        
        AFDownloadRequestOperation *downloadOperation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:tempFilePath shouldResume:NO];
        
        [downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            if([sender respondsToSelector:@selector(didDownloadDocketEntry:atPath:cost:)])
            {
                NSLog(@"%@", tempFilePath);
                [sender didDownloadDocketEntry:entry atPath:tempFilePath cost:NO];
                
                [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
                
            }
            
            
            
            
        }
         
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
        
        [self enqueueHTTPRequestOperation:downloadOperation];
        
    }
    
    else
    {
        
    }
        
   
    
}

-(void) isDocketEntryRECAPPED:(DkTDocketEntry *)entry sender:(UIViewController<RECAPClientProtocol>*)sender
{
    if( (entry.court == nil) || (entry.link == nil) ) return;
    
    NSDictionary *params = @{@"court":entry.court,
                             @"urls":@[entry.link]};
    
    
    if([sender respondsToSelector:@selector(queryForDocketEntry:json:)])
    {
        [self postPath:@"query/" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *json = [[NSJSONSerialization JSONObjectWithData:responseObject options:0 error:0] objectAtIndex:0];
            
            //filename
            //timestamp
            
            [sender queryForDocketEntry:entry json:json];
        }
         
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            [sender queryForDocketEntry:entry json:nil];
            
        }];

    }
    
        
}

-(void) isDocketEntryRECAPPED:(DkTDocketEntry *)entry completion:(DkTQueryBlock)blk
{
    if( (entry.court == nil) || (entry.link == nil) ) return;
    
    
    
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
        
        NSLog(@"%@",error);
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //iOS json encoding escapes forward slashes
        jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        
        body = [body stringByAppendingString:jsonString];
        
        
        
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        
        AFJSONRequestOperation *queryOperation = [[AFJSONRequestOperation alloc] initWithRequest:request];
        
        [queryOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSLog(@"%@",[responseObject description]);
            
            if(responseObject) blk(entry, (NSDictionary *)responseObject);
    
            else blk(entry, nil);
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            blk(entry, nil);
        }];
        
        
        [self enqueueHTTPRequestOperation:queryOperation];
    }
    
    
}


-(void) uploadDocket:(NSData *)data court:(NSString *)court caseNumber:(NSString *)casenum
{
    NSDictionary *params = @{@"court":court,
                             @"casenum":casenum};
    
    NSURLRequest *postRequest = [self  multipartFormRequestWithMethod:@"POST"
                                                                    path:@"/upload"
                                                                    parameters:params
                                                     constructingBodyWithBlock:^(id formData) {
                                                       
                                                         [formData appendPartWithFileData:data
                                                                                     name:@"latte[photo]"
                                                                                 fileName:@"latte.png"
                                                                                 mimeType:@"text/html;  charset=UTF-8"];
                                                                 }];
    AFHTTPRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:postRequest];
    [self enqueueHTTPRequestOperation:operation];
}

-(void) uploadCasePDF:(NSData *)data court:(NSString *)court url:(NSString *)url
{
    NSDictionary *params = @{@"data":data,
                             @"mimetype":@"application/pdf",
                             @"court":court,
                             @"url":url};
    [self postPath:@"/upload" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    
}

-(void) uploadDocMeta:(DkTDocketEntry *)entry
{
    NSDictionary *params = @{@"docid":entry.docID, @"court":entry.court, @"add_case_info":@"true"};
    
    
    [self postPath:@"adddocmeta" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];

}



@end

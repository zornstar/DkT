//
//  PACERClient.m
//  DkTp
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "PACERParser.h"
#import "PACERClient.h"
#import "RECAPClient.h"

#import "DkTSession.h"
#import "DkTSessionManager.h"
#import "DkTUser.h"
#import "DkTDocket.h"
#import "RECAPClient.h"
#import "DkTDocketEntry.h"
#import "AFDownloadRequestOperation.h"
#import "MBProgressHUD.h"

#define kLoginURL @"https://pacer.login.uscourts.gov/cgi-bin/check-pacer-passwd.pl"
#define kBaseURL @"https://pcl.uscourts.gov/"
#define kSearchURL @"https://pcl.uscourts.gov/dquery"
#define kViewPath @"view"



@interface PACERClient ()
{
    NSString *_court;
}
@end



@implementation PACERClient

+(RECAPClient *) recapClient
{
    return [RECAPClient sharedClient];
}



+(NSMutableDictionary *) defaultDocketParams
{
    return [@{@"date_range_type" : @"Filed",
             @"date_type" : @"filed",
             @"date_from" : @"1/1/1950",
             @"list_of_parties_and_counsel": @"off",
             @"terminated_parties" : @"off",
             @"pdf_header" : @"1",
             @"output_format" : @"html",
            @"sort1" : @"most recent date first"} mutableCopy];
    
};

+(NSMutableDictionary *) defaultAppellateDocketParams
{
    return [@{@"incDktEntries" : @"Y",
            @"incOrigDkt" : @"Y",
            @"dktType" : @"dktPublic",
            @"outputXML_TXT": @"XML",
            @"terminated_parties" : @"off",
            @"confirmCharge" : @"y",
            @"servlet" : @"CaseSummary.jsp"} mutableCopy];
    
};

+ (id)sharedClient
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[PACERClient alloc] init];
    });
    return sharedInstance;
}

-(id) init
{
    if(self = [super initWithBaseURL:[NSURL URLWithString:kBaseURL]])
    {
        self.parameterEncoding = AFFormURLParameterEncoding;
        [self registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    }
    
    return self;
}

-(void) setUser:(DkTUser *)user
{
    _user = user;
}


-(void) loginForSession:(DkTSession *)session sender:(UIViewController<PACERClientProtocol>*)sender
{
   MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:sender.view animated:YES];
    hud.color = kActiveColor;
    
    NSDictionary *params = @{@"loginid":session.user.username, @"passwd":session.user.password, @"client":session.client, @"faction":@"Login"};
    
    NSURLRequest *request = [self requestWithMethod:@"POST" path:kLoginURL parameters:params];
    
    AFHTTPRequestOperation *loginOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    if([sender respondsToSelector:@selector(handleLogin:)])
    {
        [loginOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
    
            if([PACERParser parseLogin:responseObject])
            {
                [DkTSession setCurrentSession:session];
                [[DkTSessionManager sharedManager] addSession:session];
                [sender handleLogin:(_loggedIn = TRUE)];
                [self setReceiptCookie];
            }
            
            else
            {
                [sender handleLogin:(_loggedIn = FALSE)];
            }
        
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
            [sender handleLogin:(_loggedIn = FALSE)];
        }];
    }
    [self enqueueHTTPRequestOperation:loginOperation];
    
    return;
    
}

-(void) executeSearch:(NSDictionary *)searchParams sender:(UIViewController<PACERClientProtocol>*)sender
{
    NSDictionary *params = [NSDictionary dictionaryWithDictionary:searchParams];
    
    NSURLRequest *request = [self requestWithMethod:@"POST" path:kSearchURL parameters:params];
    
    AFHTTPRequestOperation *searchOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    
    
    if([sender respondsToSelector:@selector(postSearchResults:nextPage:)])
    {
        
        [searchOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSLog(@"%@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            
            NSArray *results = [PACERParser parseSearchResults:responseObject];
            NSString * nextPage = [PACERParser parseForNextPage:responseObject];
            
            [sender postSearchResults:results nextPage:nextPage];
            
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [sender postSearchResults:nil nextPage:nil];
        }];
    
    [self enqueueHTTPRequestOperation:searchOperation];
        
    }
         
        
}

-(void) getDocket:(DkTDocket *)docket sender:(UIViewController<PACERClientProtocol>*)sender
{
    switch([docket type]) {
        case DocketTypeNone: return; break;
        case DocketTypeDistrict: { [self getDistrictDocket:docket sender:sender]; break; }
        case DocketTypeBankruptcy: { [self getDistrictDocket:docket sender:sender]; break; }
        case DocketTypeAppellate: { [self getAppellateDocket:docket sender:sender]; break; }
    }
}
-(void) getDistrictDocket:(DkTDocket *)docket sender:(UIViewController<PACERClientProtocol>*)sender
    {
    //if DkT activated
    //if(token == FALSE) [[PACERClient recapClient] getDocket:docket sender:sender];
    //end if
    
        __block NSString *requestString = [docket.link stringByReplacingOccurrencesOfString:@"iqquerymenu" withString:@"DktRpt"];
    
            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
            
            AFHTTPRequestOperation *queryDocketOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
            
            [queryDocketOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSString *docketLink = [PACERParser parseDocketSheet:responseObject courtType:PACERCourtTypeCivil];
                NSString *baseString = [requestString substringToIndex:[requestString rangeOfString:@"?"].location];
                NSString *requestString = [baseString stringByAppendingString:docketLink];
                NSMutableURLRequest *urlRequest2 = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
                
                AFHTTPRequestOperation *getDocketOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest2];
                
                [getDocketOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    if([sender respondsToSelector:@selector(handleDocket:entries:)])
                    {
                        NSArray *docketEntries = [PACERParser parseDocket:docket html:responseObject];
                        [sender handleDocket:docket entries:docketEntries];
                        
                        //if DkT activated
                        //[[PACERClient recapClient] uploadDocket:responseObject court:docket.court caseNumber:docket.docketID];
                        //end if
                        
                    }
                 
                 
                    [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    
                    
                    [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
                    
                }];
                
                [self enqueueHTTPRequestOperation:getDocketOperation];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
            }];
            
            [self enqueueHTTPRequestOperation:queryDocketOperation];
}

-(void) getDocument:(DkTDocketEntry *)entry sender:(UIViewController<PACERClientProtocol>*)sender
{
    
    NSString *courtLink = [entry courtLink];
    
    NSString *path = [entry link];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    [request setHTTPMethod:@"POST"];
    NSString *urlenc = [entry urlEncodedParams];
    NSData *form = [urlenc dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:form];
    AFHTTPRequestOperation *getDocument = [[AFHTTPRequestOperation alloc] initWithRequest:request];
/*
    NSDictionary *multi_form = @{@"caseid": entry.casenum,
                                 @"de_seq_num":entry.casenum,
                                 @"got_receipt":@1,
                                 @"pdf_header":@1,
                                 @"pdf_toggle_possible":@1
                                 };
  */  
    [getDocument setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        
        
        
        
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        if([responseString rangeOfString:@"Document Selection Menu" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            //handle multidocument
            
            if([sender respondsToSelector:@selector(handleDocumentsFromEntry:entries:)])
            {
                
                NSArray *docketEntries = [PACERParser parseDocumentPage:responseObject];
                
                [sender handleDocumentsFromEntry:entry entries:docketEntries];
            }
            
        }
        
        else {
            
            NSString *tempDir = NSTemporaryDirectory();
            
            NSLog(@"%@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]); 
            
            NSString *tempFilePath = [tempDir stringByAppendingString:[entry fileName]];
            
            NSLog(@"%@", [operation.response.allHeaderFields description]);
            
            if ([[operation.response.allHeaderFields objectForKey:@"Content-Type"] isEqualToString:@"application/pdf"]) {
                
                tempFilePath = [tempFilePath stringByAppendingPathComponent:@".pdf"];
                
                NSData *data = responseObject;
                
                [data writeToFile:tempFilePath atomically:YES];
                
                if([sender respondsToSelector:@selector(didDownloadDocketEntry:atPath:)])
                {
                    [sender didDownloadDocketEntry:entry atPath:tempFilePath];
                    
                    [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
                    
                }
                
            }
            
            else {
                
                NSString *pdfLink = [PACERParser pdfURLForDownloadDocument:responseObject];
                NSString *pdfPath = [courtLink stringByAppendingString:pdfLink];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pdfPath]];
                
                AFDownloadRequestOperation *downloadOperation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:tempFilePath shouldResume:NO];
                
                [downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    if([sender respondsToSelector:@selector(didDownloadDocketEntry:atPath:)])
                    {
                        [sender didDownloadDocketEntry:entry atPath:tempFilePath];
                        
                        [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
                        
                    }
                    
                    
                    
                    
                }
                 
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                             
                    }];
                
                [self enqueueHTTPRequestOperation:downloadOperation];
            }
                     
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", [error description]);
    }];
    
    [self enqueueHTTPRequestOperation:getDocument];
}
    
        
            
      //  [[PACERClient recapClient] uploadCasePDF:responseObject court:entry.court url:entry.link];
-(void) getAppellateDocket:(DkTDocket *)docket sender:(UIViewController<PACERClientProtocol>*)sender
{
         
        __block NSString *baseString = [NSString stringWithFormat:@"https://ecf.%@.uscourts.gov/cmecf/servlet/TransportRoom",docket.court];
            
        NSMutableDictionary *params = [PACERClient defaultAppellateDocketParams];
        [params setObject:docket.case_num forKey:@"caseNum"];
            
        NSURLRequest *urlRequest = [self requestWithMethod:@"POST" path:baseString parameters:params];
            
        AFHTTPRequestOperation *queryDocketOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
            
        [queryDocketOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSArray *docketEntries = [PACERParser parseAppellateDocket:responseObject];
                [sender handleDocket:docket entries:docketEntries];

                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    
        }];
                            
            [self enqueueHTTPRequestOperation:queryDocketOperation];
}

-(NSHTTPCookie *) receiptCookie
{
    NSMutableDictionary *cookieDict = [NSMutableDictionary dictionary];
    [cookieDict setObject:@"PacerPref" forKey:NSHTTPCookieName];
    [cookieDict setObject:@"receipt=N" forKey:NSHTTPCookieValue];
    [cookieDict setObject:@"/" forKey:NSHTTPCookiePath];
    [cookieDict setObject:@".uscourts.gov" forKey:NSHTTPCookieOriginURL];
    [cookieDict setObject:@"TRUE" forKey:NSHTTPCookieSecure];
    
    return [NSHTTPCookie cookieWithProperties:cookieDict];
}

-(void) setReceiptCookie
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:[self receiptCookie]];
}

-(void) getDocLink:(DkTDocketEntry *)entry sender:(UIViewController<PACERClientProtocol>*)sender
{
    if([sender respondsToSelector:@selector(handleDocLink:docLink:)] && entry.docLinkParam)
    {
         NSString *path = [entry courtLink];
        
        path = [path stringByAppendingString:@"cgi-bin/document_link.pl?"];
        path = [path stringByAppendingString:entry.docLinkParam];
        
        AFHTTPRequestOperation *requestOp = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:path]]];
        
        [requestOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            if([sender respondsToSelector:@selector(handleDocLink:docLink:)])
            {
                NSString *str = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                entry.docLink = str;
                [sender handleDocLink:entry docLink:str];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
        
        [requestOp start];
    }
    
}

-(void) getDocLink:(DkTDocketEntry *)entry sender:(UIViewController<PACERClientProtocol>*)sender completion:(PACERDocLinkBlock)blk
{
    if(blk && entry.docLinkParam)
    {
        NSString *path = [entry courtLink];
        
        path = [path stringByAppendingString:@"cgi-bin/document_link.pl?"];
        path = [path stringByAppendingString:entry.docLinkParam];
        
        AFHTTPRequestOperation *requestOp = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:path]]];
        
        [requestOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            if([sender respondsToSelector:@selector(handleDocLink:docLink:)])
            {
                NSString *str = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                entry.docLink = str;
                blk(entry, str);
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            blk(entry, nil);
            
        }];
        
        [requestOp start];
    }
    
}


@end

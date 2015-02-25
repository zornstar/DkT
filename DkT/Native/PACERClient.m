//
//  
//
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "PACERParser.h"
#import "PACERClient.h"
#import "DkTAlertView.h"
#import "DkTSettings.h"
#import "DkTSession.h"
#import "DkTSessionManager.h"
#import "DkTUser.h"
#import "DkTDocket.h"
#import "DkTDocketEntry.h"
#import "AFDownloadRequestOperation.h"
#import "MBProgressHUD.h"
#import "NSString+Utilities.h"
#import "SSNetworkInfo.h"
#import "GDataXMLNode.h"

#define kCSOLoginURL @"https://pacer.login.uscourts.gov/services/cso-session-rest"
#define kLoginURL @"https://pacer.login.uscourts.gov/csologin/login.jsf"
#define kBaseURL @"https://pcl.uscourts.gov/"
#define kSearchURL @"https://pcl.uscourts.gov/dquery"
#define kAppellateDocumentURL @"https://ecf.%@.uscourts.gov/cmecf/servlet/TransportRoom?servlet=ShowDoc&incPdfHeader=Y&incPdfHeaderDisp=Y&dls_id=%@&caseId=%@&pacer=t&recp=%d"

NSString *const AppellateParams = @"incPdfMulti=Y&incDktEntries=Y&dateFrom=&dateTo=&servlet=CaseSummary.jsp&caseNum=%@&fullDocketReport=Y&confirmCharge=n";

@implementation  DkTURLRequest

-(id) init
{
    if(self = [super init])
    {
        self.timeoutInterval = 15.0;
    }
    
    return self;
}
@end

@interface PACERClient ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation PACERClient

/*
+(SecondaryClient *) secondaryClient
{
    return [secondaryClient sharedClient];
}*/

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
            @"outputXML_TXT": @"XML",
            @"confirmCharge" : @"n",
            @"fullDocketReport" : @"Y",
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
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_dateFormatter setDateFormat:@"MM/dd/yyyy"];
    }
    
    return self;
}

+(PACERConnectivityStatus) connectivityStatus
{
    PACERConnectivityStatus status = PACERConnected;
    
    AFNetworkReachabilityStatus reachstatus = [[PACERClient sharedClient] networkReachabilityStatus];
    
    if(reachstatus == AFNetworkReachabilityStatusNotReachable) status = PACERConnectivityStatusNoInternet;
    
    if([DkTSession currentSession].user.username == nil)  status = status | PACERConnectivityStatusNotLoggedIn;
    
    return status;
}

-(NSString *) pacerDateString:(NSDate *)date {
    return [self.dateFormatter stringFromDate:[NSDate date]];
}

-(BOOL) checkNetworkStatusWithAlert:(BOOL)alert
{
    BOOL notConnected = (self.networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable);
    
    //check cookies
    
    if(alert && notConnected)
    {
        DkTAlertView *alertView = [[DkTAlertView alloc] initWithTitle:@"Network Error" andMessage:@"Check Network Connection"];
        [alertView addButtonWithTitle:@"OK" type:SIAlertViewButtonTypeDefault handler:^(SIAlertView *alertView) {
            [alertView dismissAnimated:YES];
        }];
        
        [alertView show];
        return FALSE;
    }
    
    else return TRUE;
}

-(void) loginForCSOSession:(DkTSession *)session sender:(UIViewController<PACERClientProtocol>*)sender {
    
    for(id cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies)
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    
    @try {
        
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kCSOLoginURL]];
    NSString * str = [NSString stringWithFormat:@"<CsoAuth><loginId>%@</loginId><password>%@</password><userIpAddress>%@</userIpAddress></CsoAuth>", session.user.username, session.user.password, [SSNetworkInfo currentIPAddress]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFHTTPRequestOperation *searchOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    [searchOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:responseObject options:0 error:nil];
        NSLog(@"%@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
        if([doc.rootElement elementsForName:@"loginResult"].count > 0 && [[[[doc.rootElement elementsForName:@"loginResult"] firstObject] stringValue] isEqualToString:@"0"]) {
            _loggedIn = TRUE;
            
            NSMutableArray *cookies = [NSMutableArray array];
            
            NSString *token = [[[doc.rootElement elementsForName:@"nextGenCSO"] firstObject] stringValue];
            if(session.client.length > 0) {
                [cookies addObject:[self cookieWithName:@"PACERClientCode" andValue:session.client]];
                
            }
            [cookies addObject:[self cookieWithName:@"NextGenCSO" andValue:token]];
            [cookies addObject:[self cookieWithName:@"PacerSession" andValue:token]];
            [cookies addObject:[self cookieWithName:@"BALANCEID" andValue:@"balancer.172.16.1.155"]];
            [DkTSession setCurrentSession:session];
            [[DkTSessionManager sharedManager] addSession:session];
            
            
            for(NSHTTPCookie *cookie in cookies) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            }
            
            [self setReceiptCookie];
            
            
        } else _loggedIn = FALSE;
        
        if([sender respondsToSelector:@selector(handleLogin:)]) [sender handleLogin:_loggedIn];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if([sender respondsToSelector:@selector(handleLogin:)]) [sender handleLogin:(_loggedIn = FALSE)];
    }];
    
    [self enqueueHTTPRequestOperation:searchOperation];
    
    }
    @catch (NSException *exception) {
        
        if([sender respondsToSelector:@selector(handleLogin:)]) [sender handleLogin:(_loggedIn = FALSE)];
        
    }
    @finally {
        
    }

}

//DEPRECATED
-(void) loginForSession:(DkTSession *)session sender:(UIViewController<PACERClientProtocol>*)sender
{
    
    for(id cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies)
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:@{@"BALANCEID":NSHTTPCookieName,@"balancer.172.16.1.155":NSHTTPCookieValue}];
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    @try {
        
        DkTURLRequest *request = [DkTURLRequest requestWithURL:[NSURL URLWithString:kLoginURL]];
        
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        
        AFHTTPRequestOperation *firstLogin = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [firstLogin setCacheResponseBlock:^NSCachedURLResponse *(NSURLConnection *connection, NSCachedURLResponse *cachedResponse) {
            return nil;
        }];
        
        [firstLogin setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSString *token = [PACERParser loginToken:responseObject];
            
            NSDictionary *params = @{
                                     @"login":@"login",
                                     @"login:loginName":session.user.username,
                                     @"login:password":session.user.password,
                                     @"login:clientCode":session.client,
                                     token:@"",
                                     @"javax.faces.ViewState":@"stateless"
                                    };
            
            DkTURLRequest *request = [[self requestWithMethod:@"POST" path:@"https://pacer.login.uscourts.gov/csologin/login.jsf" parameters:params] mutableCopy];
            [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
            
            AFHTTPRequestOperation *loginOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            
            [loginOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                if([operation.response.allHeaderFields[@"Pragma"] containsString:@"revalidate"]) {
                    
                    NSString *checkboxToken = [PACERParser checkboxToken:responseObject];
                    
                    
                    NSDictionary *cparams = @{
                                             @"regmsg":@"regmsg",
                                             checkboxToken:@"on",
                                             @"regmsg:bpmConfirm":@"",
                                             @"javax.faces.ViewState":@"stateless"
                                             };
                    DkTURLRequest *checkboxRequest = [[self requestWithMethod:@"POST" path:@"https://pacer.login.uscourts.gov/csologin/login.jsf" parameters:cparams] mutableCopy];
                    [checkboxRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
                    
                    AFHTTPRequestOperation *checkboxOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
                    
                    [checkboxOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                        
                        [DkTSession setCurrentSession:session];
                        [[DkTSessionManager sharedManager] addSession:session];
                        [self setReceiptCookie];
                        _loggedIn = TRUE;
                        
                        if([sender respondsToSelector:@selector(handleLogin:)]) [sender handleLogin:_loggedIn];
                        
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        
                        if([sender respondsToSelector:@selector(handleLogin:)]) [sender handleLogin:(_loggedIn = FALSE)];
                    }];
                    
                    [self enqueueHTTPRequestOperation:checkboxOperation];
                }
                
                else if([PACERParser parseLogin:responseObject])
                {
                    [DkTSession setCurrentSession:session];
                    [[DkTSessionManager sharedManager] addSession:session];
                    [self setReceiptCookie];
                    _loggedIn = TRUE;
                    
                    if([sender respondsToSelector:@selector(handleLogin:)]) [sender handleLogin:_loggedIn];
                } else {
                    _loggedIn = FALSE;
                    if([sender respondsToSelector:@selector(handleLogin:)]) [sender handleLogin:_loggedIn];
                }
                
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                if([sender respondsToSelector:@selector(handleLogin:)]) [sender handleLogin:(_loggedIn = FALSE)];
            }];
            
            [self enqueueHTTPRequestOperation:loginOperation];
            
            return;

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if([sender respondsToSelector:@selector(handleLogin:)]) [sender handleLogin:(_loggedIn = FALSE)];
        }];
        [self enqueueHTTPRequestOperation:firstLogin];
        
        
        
    }
    
    @catch (NSException *exception) {
        
        if([sender respondsToSelector:@selector(handleLogin:)]) [sender handleLogin:(_loggedIn = FALSE)];

    }
    @finally {
        
    }
    
}

-(void) executeSearch:(NSDictionary *)searchParams sender:(UIViewController<PACERClientProtocol>*)sender
{
    NSLog(@"%@", [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies].description);
     if([self checkNetworkStatusWithAlert:YES])
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
}

-(void) retrieveDocket:(DkTDocket *)docket sender:(UIViewController<PACERClientProtocol>*)sender { [self retrieveDocket:docket sender:sender to:nil from:nil]; }

-(void) retrieveDocket:(DkTDocket *)docket sender:(UIViewController<PACERClientProtocol>*)sender to:(NSString *)to from:(NSString *)from
{
    if(from == nil) from = @"";
    if(to == nil) to = @"";
    
    if([self checkNetworkStatusWithAlert:YES])
    {
        switch([docket type]) {
            case DocketTypeNone: return; break;
            case DocketTypeDistrict: { [self getDistrictDocket:docket sender:sender to:to from:from]; break; }
            case DocketTypeBankruptcy: { [self getBankruptcyDocket:docket sender:sender to:to from:from]; break; }
            case DocketTypeAppellate: { [self getAppellateDocket:docket sender:sender to:to from:from]; break; }
        }
    }
    
    else {
        
        if([sender respondsToSelector:@selector(handleFailedConnection)]) [sender handleFailedConnection];
        [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
    }
}
-(void) getDistrictDocket:(DkTDocket *)docket sender:(UIViewController<PACERClientProtocol>*)sender to:(NSString *)to from:(NSString *)from
{
    
        __block NSString *requestString = [docket.link stringByReplacingOccurrencesOfString:@"iqquerymenu" withString:@"DktRpt"];
    
        DkTURLRequest *urlRequest = [DkTURLRequest requestWithURL:[NSURL URLWithString:requestString]];
            
        AFHTTPRequestOperation *queryDocketOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
        
        void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error);
        
        failureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
            if([sender respondsToSelector:@selector(view)]) [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
            if([sender respondsToSelector:@selector(handleDocketError:)]) [sender handleDocketError:docket];
        };
        
        [queryDocketOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                
            NSString *docketLink = [PACERParser parseDocketSheet:responseObject courtType:PACERCourtTypeCivil];
            NSString *baseString = [requestString substringToIndex:[requestString rangeOfString:@"?"].location];
            NSString *requestString = [baseString stringByAppendingString:docketLink];
                
            NSMutableURLRequest *urlRequest2 = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
                
            [urlRequest2 setHTTPMethod:@"POST"];
            NSString *boundary = [[NSString randomStringWithLength:10] stringByAppendingString:@"-----"];
            NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
            [urlRequest2 addValue:contentType forHTTPHeaderField:@"Content-Type"];
                
            NSData *data = [self dcParamsWithDocket:docket boundary:boundary to:to from:from];
            [urlRequest2 setHTTPBody:data];
                
            AFHTTPRequestOperation *getDocketOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest2];
        
            [getDocketOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                NSString *str = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                    
                //Run a check to see if we came to a too many docket entry page
                    
                if([str rangeOfString:@"The report may take a long time to run because this case has many docket entries."].location != NSNotFound) {
                    
                    NSString *url3 = [PACERParser parseMore:responseObject docket:docket];
                    DkTURLRequest *urlRequest3 = [DkTURLRequest requestWithURL:[NSURL URLWithString:url3]];
                    [urlRequest3 setHTTPMethod:@"POST"];
                    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
                    [urlRequest3 addValue:contentType forHTTPHeaderField:@"Content-Type"];
                    
                    NSMutableData *d = [NSMutableData data];
                    [d appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                    [d appendData:[@"Content-Disposition: form-data; name=\"date_from\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    [d appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                    [urlRequest3 setHTTPBody:d];
                        
                    AFHTTPRequestOperation *queryDocketOperation3 = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest3];
                    
                    [queryDocketOperation3 setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                            
                        if([sender respondsToSelector:@selector(handleDocket:entries:to:from:)])
                        {
                            docket.updated = [self pacerDateString:[NSDate date]];
                            dispatch_async(dispatch_queue_create("com.DkT.parse", 0), ^{
                                NSArray *docketEntries = [PACERParser parseDocket:docket html:responseObject];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [sender handleDocket:docket entries:docketEntries to:to from:from];
                                        /* if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryEnabledKey] boolValue] && (to.length == 0) && (from.length == 0))
                                         {
                                         [[PACERClient secondaryClient] uploadDocket:responseObject docket:docket];
                                         }*/
                                    });
                                });
                            }
                        
                        if([sender respondsToSelector:@selector(view)]) [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
                        
                    } failure:failureBlock];
                    
                        [self enqueueHTTPRequestOperation:queryDocketOperation3];
                    }
                    
                    
                    else if([sender respondsToSelector:@selector(handleDocket:entries:to:from:)])
                    {
                        docket.updated = [self pacerDateString:[NSDate date]];
                        dispatch_async(dispatch_queue_create("com.DkT.parse", 0), ^{
                            NSArray *docketEntries = [PACERParser parseDocket:docket html:responseObject];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [sender handleDocket:docket entries:docketEntries to:to from:from];
                                /* if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryEnabledKey] boolValue] && (to.length == 0) && (from.length == 0))
                                 {
                                 [[PACERClient secondaryClient] uploadDocket:responseObject docket:docket];
                                 }*/
                            });
                        });
                        
                        if([sender respondsToSelector:@selector(view)]) [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
                    }
                 
                
            
            } failure:failureBlock];
            
                [self enqueueHTTPRequestOperation:getDocketOperation];
                
        } failure:failureBlock];
    
            [self enqueueHTTPRequestOperation:queryDocketOperation];
}

-(void) getBankruptcyDocket:(DkTDocket *)docket sender:(UIViewController<PACERClientProtocol>*)sender to:(NSString *)to from:(NSString *)from
{
    __block NSString *requestString = [docket.link stringByReplacingOccurrencesOfString:@"iqquerymenu" withString:@"DktRpt"];
    
    void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    failureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if([sender respondsToSelector:@selector(view)]) [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
        if([sender respondsToSelector:@selector(handleDocketError:)]) [sender handleDocketError:docket];
    };
    
    DkTURLRequest *urlRequest = [DkTURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    AFHTTPRequestOperation *queryDocketOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    
    [queryDocketOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *docketLink = [PACERParser parseDocketSheet:responseObject courtType:PACERCourtTypeCivil];
        NSString *baseString = [requestString substringToIndex:[requestString rangeOfString:@"?"].location];
        NSString *requestString = [baseString stringByAppendingString:docketLink];
       
        DkTURLRequest *urlRequest2 = [DkTURLRequest requestWithURL:[NSURL URLWithString:requestString]];
        
        [urlRequest2 setHTTPMethod:@"POST"];
        NSString *boundary = [[NSString randomStringWithLength:10] stringByAppendingString:@"-----"];
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [urlRequest2 addValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        NSData *data = [self bkParamsWithDocket:docket boundary:boundary to:to from:from];
        [urlRequest2 setHTTPBody:data];
        
        AFHTTPRequestOperation *getDocketOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest2];
        
        [getDocketOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            if([sender respondsToSelector:@selector(handleDocket:entries:to:from:)])
            {
               
                docket.updated = [_dateFormatter stringFromDate:[NSDate date]];
                NSArray *docketEntries = [PACERParser parseDocket:docket html:responseObject];
                [sender handleDocket:docket entries:docketEntries to:to from:from];
                
               /* if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryClientEnabledKey] boolValue] && (to.length == 0) && (from.length == 0))
                {
                    [[PACERClient secondaryClient] uploadDocket:responseObject docket:docket];
                }*/
                
            }
            
            
            [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
        } failure:failureBlock];
        
        [self enqueueHTTPRequestOperation:getDocketOperation];
        
    } failure:failureBlock];
    
    [self enqueueHTTPRequestOperation:queryDocketOperation];
}

-(NSData *) bkParamsWithDocket:(DkTDocket *)docket boundary:(NSString *)boundary to:(NSString *)to from:(NSString *)from
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:docket.case_num forKey:@"case_num"];
    [dict setObject:@"html" forKey:@"output_format"];
    [dict setObject:@"oldest date first" forKey:@"sort1"];
    [dict setObject:@"filed" forKey:@"date_type"];
    NSString *str = [docket.link substringFromIndex:[docket.link rangeOfString:@"?"].location+1];
    [dict setObject:str forKey:@"all_case_ids"];
    
    [dict setObject:from forKey:@"date_from"];
    [dict setObject:to forKey:@"date_to"];
    
    [dict setObject:to forKey:@"documents_numbered_to_"];
    [dict setObject:from forKey:@"documents_numbered_from_"];
    
    NSMutableData *data = [NSMutableData data];
    
    NSArray *keys = [dict allKeys];
    
    for (NSDictionary *key in keys) {
        [data appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:[[NSString stringWithFormat:@"%@\r\n", [dict objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return data;
}

-(NSData *) dcParamsWithDocket:(DkTDocket *)docket boundary:(NSString *)boundary to:(NSString *)to from:(NSString *)from
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:docket.case_num forKey:@"case_num"];
    [dict setObject:@"html" forKey:@"output_format"];
    [dict setObject:@"oldest date first" forKey:@"sort1"];
    [dict setObject:@"filed" forKey:@"date_type"];
    NSString *str = [docket.link substringFromIndex:[docket.link rangeOfString:@"?"].location+1];
    [dict setObject:str forKey:@"all_case_ids"];
    
    
    [dict setObject:from forKey:@"date_from"];
    [dict setObject:to forKey:@"date_to"];
    
  //  [dict setObject:to forKey:@"documents_numbered_to_"];
  //  [dict setObject:from forKey:@"documents_numbered_from_"];
    
    NSMutableData *data = [NSMutableData data];
    
    NSArray *keys = [dict allKeys];
    
    for (NSDictionary *key in keys) {
        [data appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:[[NSString stringWithFormat:@"%@\r\n", [dict objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return data;
}


-(NSString *) apParamsWithDocket:(DkTDocket *)docket to:(NSString *)to from:(NSString *)from
{
    NSString *str = [NSString stringWithFormat:@"?incPdfMulti=Y&incDktEntries=Y&dateFrom=%@&dateTo=%@&servlet=CaseSummary.jsp&caseNum=%@&fullDocketReport=Y&confirmCharge=n",from, to, docket.case_num];
    return str;
    
}


-(void) retrieveDocument:(DkTDocketEntry *)entry sender:(id<PACERClientProtocol>)sender docket:(DkTDocket *)docket
{
    if([self checkNetworkStatusWithAlert:YES])
    {
        switch(docket.type) {
            case DocketTypeNone: return; break;
            case DocketTypeDistrict: { [self getDistrictDocument:entry sender:sender docket:docket]; break; }
            case DocketTypeBankruptcy: { [self getDistrictDocument:entry sender:sender docket:docket]; break; }
            case DocketTypeAppellate: { [self getAppellateDocument:entry sender:sender docket:docket]; break; }
        }
    }
    
    
    else if([sender isKindOfClass:[UIViewController class]])
    {
        [MBProgressHUD hideAllHUDsForView:[(UIViewController *)sender view] animated:YES];
    }
}


-(void) getAppellateDocument:(DkTDocketEntry *)entry sender:(id<PACERClientProtocol>)sender docket:(DkTDocket *)docket
{
    
    NSString *tempDir = NSTemporaryDirectory();
    NSString *tempFilePath = [tempDir stringByAppendingString:[entry tempFileName]];
    
    //if file exists at temp path, then just get it from temppath
    if([[NSFileManager defaultManager] fileExistsAtPath:tempFilePath])
    {
        if([sender respondsToSelector:@selector(didDownloadDocketEntry:atPath:cost:)])
        {
            [sender didDownloadDocketEntry:entry atPath:tempFilePath cost:NO];
        }
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:kAppellateDocumentURL, [docket shortCourt], entry.docID, docket.cs_caseid,(int)(CFAbsoluteTimeGetCurrent()+NSTimeIntervalSince1970)];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    AFHTTPRequestOperation *getDocument = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    
    [getDocument setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        if(responseString)
        {
            if([responseString rangeOfString:@"Documents" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                //handle multidocument
                
                if([sender respondsToSelector:@selector(handleDocumentsFromDocket:entry:entries:)])
                {
                    
                    /*if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryClientEnabledKey] boolValue])
                    {
                        [[PACERClient secondaryClient] uploadCasePDF:responseObject docketEntry:entry];
                    }*/
                    
                    NSArray *docketEntries = [PACERParser parseAppellateMultiDoc:entry html:responseObject];
                    
                    [sender handleDocumentsFromDocket:docket entry:entry entries:docketEntries];
                }
                
            }
            
            else if (([responseString rangeOfString:@"You do not have permission to view this document." options:NSCaseInsensitiveSearch].location !=NSNotFound) || [responseString rangeOfString:@"Under Seal" options:NSCaseInsensitiveSearch].location !=NSNotFound) {
                
                if([sender respondsToSelector:@selector(handleSealedDocument:)])
                {
                    [sender handleSealedDocument:entry];
                }
            }
        }
        
        else {
            
            if ([[operation.response.allHeaderFields objectForKey:@"Content-Type"] isEqualToString:@"application/pdf"]) {
                
                NSData *data = responseObject;
                
                [data writeToFile:tempFilePath atomically:YES];
                
                if([sender respondsToSelector:@selector(didDownloadDocketEntry:atPath:)]) [sender didDownloadDocketEntry:entry atPath:tempFilePath];
                
                /*if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryClientEnabledKey] boolValue])
                {
                    [[PACERClient secondaryClient] uploadCasePDF:responseObject docketEntry:entry];
                }*/
                
            }
        }
                
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if([sender respondsToSelector:@selector(handleDocketEntryError:)]) [sender handleDocketEntryError:entry];
        
    }];
    
    [self enqueueHTTPRequestOperation:getDocument];

}

-(void) getDistrictDocument:(DkTDocketEntry *)entry sender:(id<PACERClientProtocol>)sender docket:(DkTDocket *)docket
{
    NSString *tempDir = NSTemporaryDirectory();
    NSString *tempFilePath = [tempDir stringByAppendingString:[entry tempFileName]];
    
    //if file exists at temp path, then just get it from temppath
    if([[NSFileManager defaultManager] fileExistsAtPath:tempFilePath])
    {
        if([sender respondsToSelector:@selector(didDownloadDocketEntry:atPath:cost:)]) [sender didDownloadDocketEntry:entry atPath:tempFilePath cost:NO];
        return;
    }
    
    NSString *courtLink = [entry courtLink];
    
    NSString *path = [entry link];
    
    DkTURLRequest *request = [DkTURLRequest requestWithURL:[NSURL URLWithString:path]];
    [request setHTTPMethod:@"POST"];
    NSString *urlenc = [entry urlEncodedParams];
    urlenc = (urlenc.length > 0) ? [urlenc stringByAppendingString:@"&got_receipt=1"] : @"got_receipt=1";
    urlenc = [urlenc stringByAppendingString:@"&pdf_header=1"];
    NSData *form = [urlenc dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:form];
    
    AFHTTPRequestOperation *getDocument = [[AFHTTPRequestOperation alloc] initWithRequest:request];
  
    [getDocument setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        
        if(responseString && [responseString rangeOfString:@"Document Selection Menu" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            //handle multidocument
            
            if([sender respondsToSelector:@selector(handleDocumentsFromDocket:entry:entries:)])
            {
                /*
                if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryClientEnabledKey] boolValue])
                {
                    [[PACERClient secondaryClient] uploadCasePDF:responseObject docketEntry:entry];
                }*/

                NSArray *docketEntries = [PACERParser parseMultiDoc:entry html:responseObject];
                    
                [sender handleDocumentsFromDocket:docket entry:entry entries:docketEntries];
            }
        }
        
        else if (responseString && (([responseString rangeOfString:@"You do not have permission to view this document." options:NSCaseInsensitiveSearch].location !=NSNotFound) || [responseString rangeOfString:@"Under Seal" options:NSCaseInsensitiveSearch].location !=NSNotFound)) {
            
            if([sender respondsToSelector:@selector(handleSealedDocument:)])
            {
                [sender handleSealedDocument:entry];
            }
        }
        
        else {
            
            if ([[operation.response.allHeaderFields objectForKey:@"Content-Type"] isEqualToString:@"application/pdf"]) {
                
                
                NSData *data = responseObject;
                
                [data writeToFile:tempFilePath atomically:YES];
                
                if([sender respondsToSelector:@selector(didDownloadDocketEntry:atPath:cost:)])
                {
                    [sender didDownloadDocketEntry:entry atPath:tempFilePath cost:YES];
                    
                }
                
                /*if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryClientEnabledKey] boolValue])
                {
                    [[PACERClient secondaryClient] uploadCasePDF:responseObject docketEntry:entry];
                
                }*/
                
                
            }
            
            else {
                
                NSString *pdfLink = [PACERParser pdfURLForDownloadDocument:responseObject];
                NSString *pdfPath = [courtLink stringByAppendingString:pdfLink];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pdfPath]];
                
                AFDownloadRequestOperation *downloadOperation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:tempFilePath shouldResume:NO];
                
                [downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    if([sender respondsToSelector:@selector(didDownloadDocketEntry:atPath:cost:)])
                    {
                        [sender didDownloadDocketEntry:entry atPath:tempFilePath cost:YES];
                    
                        
                    }
                    
                    
                    /*if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryClientEnabledKey] boolValue])
                    {
                        NSData *pdf = [NSData dataWithContentsOfFile:tempFilePath];
                        [[PACERClient secondaryClient] uploadCasePDF:pdf docketEntry:entry];
                        
                    }*/
                    
                }
                 
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    
                    if([sender respondsToSelector:@selector(handleDocketEntryError:)]) [sender handleDocketEntryError:entry];
                    
                    }];
                
                [self enqueueHTTPRequestOperation:downloadOperation];
            }
                     
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
     
        
        if([sender respondsToSelector:@selector(handleDocketEntryError:)]) [sender handleDocketEntryError:entry];
    }];
    
    [self enqueueHTTPRequestOperation:getDocument];
}


-(void) getAppellateDocket:(DkTDocket *)docket sender:(UIViewController<PACERClientProtocol>*)sender to:(NSString *)to from:(NSString *)from
{ 
    NSString *urlString = [docket.courtLink stringByAppendingString:([docket.court rangeOfString:@"bap" options:NSCaseInsensitiveSearch].location != NSNotFound) ?  @"cmecf-bap-live/servlet/TransportRoom" : @"cmecf/servlet/TransportRoom"];
    
    void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error);
    
    failureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if([sender respondsToSelector:@selector(view)]) [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
        if([sender respondsToSelector:@selector(handleDocketError:)]) [sender handleDocketError:docket];
    };
    
    
     if(docket.cs_caseid.length == 0) {
        
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"?servlet=CaseSelectionTable.jsp&csnum1=%@&csnum2=%@&aName=&searchPty=pty", docket.case_num, docket.case_num]];
        DkTURLRequest *request = [DkTURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"GET"];
        AFHTTPRequestOperation *queryDocketOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [queryDocketOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            [PACERParser parseAppellateCaseSelectionPage:responseObject withDocket:docket completion:^(NSString *cs_caseid) {
    
                if(cs_caseid.length > 0) [self getAppellateDocket:docket sender:sender to:to from:from];
                
                else
                {
                    [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
                    
                    if([sender respondsToSelector:@selector(handleDocketError:)]) [sender handleDocketError:docket];
                    
                }
                
            }];
            
        } failure:failureBlock];

        [self enqueueHTTPRequestOperation:queryDocketOperation];
        return;
    }
    
    urlString = [urlString stringByAppendingString:[self apParamsWithDocket:docket to:to from:from]];
    
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    AFHTTPRequestOperation *queryDocketOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [queryDocketOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
        dispatch_async(dispatch_queue_create("com.DkT.parse", 0), ^{
            NSArray *docketEntries = [PACERParser parseAppellateDocket:docket html:responseObject];
            dispatch_async(dispatch_get_main_queue(), ^{
                    docket.updated = [_dateFormatter stringFromDate:[NSDate date]];
                    [sender handleDocket:docket entries:docketEntries to:to from:from];
            });
        });
        
        /*if([[[DkTSettings sharedSettings] valueForKey:DkTSettingsSecondaryClientEnabledKey] boolValue] && (to.length == 0) && (from.length == 0))
         {
         [[PACERClient secondaryClient] uploadDocket:responseObject docket:docket];
         }*/
        
        if([sender respondsToSelector:@selector(view)]) [MBProgressHUD hideAllHUDsForView:sender.view animated:YES];
        
    } failure:failureBlock];
    
    [self enqueueHTTPRequestOperation:queryDocketOperation];
}


-(NSHTTPCookie *) cookieWithName:(NSString *)name andValue:(NSString *)value {
    NSMutableDictionary *cookieDict = [NSMutableDictionary dictionary];
    [cookieDict setObject:name forKey:NSHTTPCookieName];
    [cookieDict setObject:value forKey:NSHTTPCookieValue];
    [cookieDict setObject:@"/" forKey:NSHTTPCookiePath];
    [cookieDict setObject:@".uscourts.gov" forKey:NSHTTPCookieDomain];
    [cookieDict setObject:@"TRUE" forKey:NSHTTPCookieSecure];
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieDict];
    return cookie;
}

-(NSData *) appellateDocumentParams:(NSString *)boundary docID:(NSString *)docID caseNum:(NSString *)caseNum
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@"ShowDoc" forKey:@"servlet"];
    [dict setObject:@"Y" forKey:@"incPdfHeader"];
    [dict setObject:@"Y" forKey:@"incPdfHeaderDisp"];
    [dict setObject:docID forKey:@"dls_id"];
    [dict setObject:docID forKey:@"caseId"];
    [dict setObject:@"t" forKey:@"pacer"];
    [dict setObject:[NSString stringWithFormat:@"%f", CFAbsoluteTimeGetCurrent()+NSTimeIntervalSince1970] forKey:@"recp"];
    
    
    NSMutableData *data = [NSMutableData data];
    
    NSArray *keys = [dict allKeys];
    
    for (NSDictionary *key in keys) {
        [data appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:[[NSString stringWithFormat:@"%@\r\n", [dict objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return data;
    
    
}

-(void) getDocLink:(DkTDocketEntry *)entry sender:(UIViewController<PACERClientProtocol>*)sender completion:(PACERDocLinkBlock)blk
{
    if(blk && entry.docLinkParam)
    {
        NSString *path = [entry courtLink];
        
        path = [path stringByAppendingString:@"cgi-bin/document_link.pl?"];
        path = [path stringByAppendingString:entry.docLinkParam];
        
        AFHTTPRequestOperation *requestOp = [[AFHTTPRequestOperation alloc] initWithRequest:[DkTURLRequest requestWithURL:[NSURL URLWithString:path]]];
        
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

-(void) setReceiptCookie
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:[self cookieWithName:@"PacerPref" andValue:@"receipt=N"]];
}

@end

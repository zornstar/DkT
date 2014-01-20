
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"
#import "DkTDocket.h"


//TODO
//switch to completion blocks

typedef NS_OPTIONS(NSUInteger, PACERConnectivityStatus) {
    PACERConnected = (1 << 0),
    PACERConnectivityStatusNoInternet = (1 << 1),
    PACERConnectivityStatusNotLoggedIn = (1 << 2)
};

@class DkTDocketEntry, /*SecondaryClient,*/ DkTSearchViewController, DkTSession, DKTAttachment;

typedef void (^PACERDocLinkBlock)(id entry, id link);

@protocol PACERClientProtocol <NSObject>

@optional

-(void) postSearchResults:(NSArray *)results nextPage:(NSString *)nextPage;
-(void) handleDocket:(DkTDocket *)docket entries:(NSArray *)entries to:(NSString *)to from:(NSString *)from;
-(void) handleDocument:(DkTDocketEntry *)entry atPath:(NSString *)path;
-(void) handleSealedDocument:(DkTDocketEntry *)entry;
-(void) handleDocketEntryError:(DkTDocketEntry *)entry;
-(void) handleDocketError:(DkTDocket *)docket;
-(void) handleLogin:(BOOL)success;
-(void) handleDocumentsFromDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry entries:(NSArray *)entries;
-(void) handleDocLink:(DkTDocketEntry *)entry docLink:(NSString *)docLink;
-(void) handleFailedConnection;
-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path;
-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path cost:(BOOL)paid;

-(void) setReceiptCookie;

@end

@interface PACERClient : AFHTTPClient

+(id) sharedClient;
+(PACERConnectivityStatus) connectivityStatus;

-(BOOL) checkNetworkStatusWithAlert:(BOOL)alert;
-(NSString *) pacerDateString:(NSDate *)date;

-(void) executeSearch:(NSDictionary *)searchParams sender:(DkTSearchViewController *)sender;
-(void) loginForSession:(DkTSession *)session sender:(id<PACERClientProtocol>)sender;
-(void) retrieveDocket:(DkTDocket *)docket sender:(id<PACERClientProtocol>)sender;
-(void) retrieveDocket:(DkTDocket *)docket sender:(id<PACERClientProtocol>)sender to:(NSString *)to from:(NSString *)from;
-(void) retrieveDocument:(DkTDocketEntry *)entry sender:(id<PACERClientProtocol>)sender docket:(DkTDocket *)docket;
-(void) retrieveDocumentLink:(DkTDocketEntry *)entry sender:(id<PACERClientProtocol>)sender;


@property (nonatomic, getter = isLoggedIn) BOOL loggedIn;

@end

@interface DkTURLRequest : NSMutableURLRequest

@end

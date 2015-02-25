
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"
#import "DkTDocket.h"


//TODO: switch to completion blocks

typedef NS_OPTIONS(NSUInteger, PACERConnectivityStatus) {
    PACERConnected = (1 << 0),
    PACERConnectivityStatusNoInternet = (1 << 1),
    PACERConnectivityStatusNotLoggedIn = (1 << 2)
};

@class DkTDocketEntry, /*SecondaryClient,*/ DkTSearchViewController, DkTSession, DKTAttachment;

typedef void (^PACERDocLinkBlock)(id entry, id link);
//typedef void (^PACERDocumentDownloadBlock)(DkTDocketEntry *entry, DkTDocket *docket, NSString *attachmentPath);

@protocol PACERClientProtocol <NSObject>

@optional

/**
 postSearchResults
    - sends to the delegate
        results: an array of DkTDocket objects corresponding to the dockets on an individual pacer search page
        nextPage: a string containing the url of the next page
 */
-(void) postSearchResults:(NSArray *)results nextPage:(NSString *)nextPage;

/**
 handleDocket
    - sends to the delegate a reference to a docket and docket entries, usually in response to a PACERClient call retrieveDocket
        docket: a docket object, usually from the search results page
        entries: the docket entries of the docket object
        to: a string date corresponding to the end period on the docket retrieval (time period limit)
        from: a string date corresponding to the start period for the docket retrieval (time period limit)
 */
-(void) handleDocket:(DkTDocket *)docket entries:(NSArray *)entries to:(NSString *)to from:(NSString *)from;

/**
 handleDocument
    - sends to the delegate a reference to a docket entry and the string path of where the downloaded document associated with that entry may be found, usually in response to a PACERClient call retrieveDocument
        entry: a docket entry (previously selected)
        path: path to find the docket entry
 */

-(void) handleDocument:(DkTDocketEntry *)entry atPath:(NSString *)path;

/**
 handleDocument
 - sends to the delegate a reference to a docket entry that is a sealed document */

-(void) handleSealedDocument:(DkTDocketEntry *)entry;

/**
 handleDocketEntryError
 - sends to the delegate a reference to a docket entry that is a docket entry error */

-(void) handleDocketEntryError:(DkTDocketEntry *)entry;

/**
 handleDocketError
 - sends to the delegate a reference to a docket where there is an error */

-(void) handleDocketError:(DkTDocket *)docket;

/**
 handleLogin
 - sends to the delegate a bool indicating success of a login */

-(void) handleLogin:(BOOL)success;

/**
 handleDocumentsFromDocket
 - sends to the delegate a reference to docket, entry, and entries corresponding to the docketEntry */

-(void) handleDocumentsFromDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry entries:(NSArray *)entries;

-(void) handleDocLink:(DkTDocketEntry *)entry docLink:(NSString *)docLink;
-(void) handleFailedConnection;
-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path;
-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path cost:(BOOL)paid;

/**
 handleDocumentsFromDocket
 - sets cookie to disable receipt page */
-(void) setReceiptCookie;

@end

@interface PACERClient : AFHTTPClient

+(id) sharedClient;
+(PACERConnectivityStatus) connectivityStatus;

-(BOOL) checkNetworkStatusWithAlert:(BOOL)alert;
-(NSString *) pacerDateString:(NSDate *)date;

-(void) executeSearch:(NSDictionary *)searchParams sender:(DkTSearchViewController *)sender;
-(void) loginForSession:(DkTSession *)session sender:(id<PACERClientProtocol>)sender; //deprecated
-(void) retrieveDocket:(DkTDocket *)docket sender:(id<PACERClientProtocol>)sender;
-(void) retrieveDocket:(DkTDocket *)docket sender:(id<PACERClientProtocol>)sender to:(NSString *)to from:(NSString *)from;
-(void) retrieveDocument:(DkTDocketEntry *)entry sender:(id<PACERClientProtocol>)sender docket:(DkTDocket *)docket;
-(void) loginForCSOSession:(DkTSession *)session sender:(UIViewController<PACERClientProtocol>*)sender;

//-(void) retrieveDocument:(DkTDocketEntry *)entry docket:(DkTDocket *)docket completion:(PACERDocumentDownloadBlock)completion;

@property (nonatomic, getter = isLoggedIn) BOOL loggedIn;

@end

@interface DkTURLRequest : NSMutableURLRequest

@end

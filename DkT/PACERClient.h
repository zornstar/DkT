//
//  PACERClient.h
//  DkTp
//
//  Created by Matthew Zorn on 5/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"

@class DkTDocket, DkTDocketEntry, RECAPClient, DkTSearchViewController, DkTSession;

typedef void (^PACERDocLinkBlock)(id entry, id link);

@protocol PACERClientProtocol <NSObject>

@optional
-(void) handleDocket:(DkTDocket *)docket entries:(NSArray *)entries;
-(void) handleDocument:(DkTDocketEntry *)entry atPath:(NSString *)path;
-(void) handleLogin:(BOOL)success;
-(void) postSearchResults:(NSArray *)results nextPage:(NSString *)nextPage;
-(void) handleDocumentsFromEntry:(DkTDocketEntry *)entry entries:(NSArray *)entries;
-(void) handleDocLink:(DkTDocketEntry *)entry docLink:(NSString *)docLink;
-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path;
-(void) didDownloadDocketEntry:(DkTDocketEntry *)entry atPath:(NSString *)path cost:(BOOL)paid;
-(void) handleMultidocRequest:(DkTDocketEntry *)entry entries:(NSArray *)entries;
@end

@class DkTUser;

@interface PACERClient : AFHTTPClient

+(id) sharedClient;
-(void) executeSearch:(NSDictionary *)searchParams sender:(DkTSearchViewController *)sender;
-(void) loginForSession:(DkTSession *)session sender:(UIViewController<PACERClientProtocol>*)sender;
-(void) getDocket:(DkTDocket *)docket sender:(UIViewController<PACERClientProtocol>*)sender;
-(void) getDocument:(DkTDocketEntry *)entry sender:(UIViewController<PACERClientProtocol>*)sender;
-(void) setUser:(DkTUser *)user;
-(void) getDocLink:(DkTDocketEntry *)entry sender:(UIViewController<PACERClientProtocol>*)sender;

@property (nonatomic, strong, readonly) DkTUser *user;

@property (nonatomic, getter = isLoggedIn) BOOL loggedIn;

@end

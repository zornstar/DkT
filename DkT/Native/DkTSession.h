//
//  Created by Matthew Zorn on 5/26/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DkTUser;

@protocol DkTSessionDelegate <NSObject>

@optional

-(void) didChangeUser:(DkTUser *)user;
-(void) didLoginUser:(DkTUser *)user;
-(void) cookieDidExpireWithReveal:(BOOL)reveal;

@end

@interface DkTSession : NSObject

@property (nonatomic, strong) DkTUser *user;

@property (nonatomic, copy) NSString *client;
@property (nonatomic, copy, readonly) NSString *costString;

@property (nonatomic) float cost;

@property (nonatomic, weak) id<DkTSessionDelegate> delegate;

+ (id)sharedInstance;
+(DkTSession *) currentSession;
+(void) setCurrentSession:(DkTSession *)session;
+ (void) addCost:(float)money;
+ (void) addCostForPages:(NSUInteger)pages;
+(void) nullifyCurrentSession;

@end


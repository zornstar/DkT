//
//  DkTUserManager.h
//  DkTp
//
//  Created by Matthew Zorn on 6/27/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DkTUser, DkTSession;

@interface DkTSessionManager : NSObject

+(id) sharedManager;
+(DkTSession *) lastSession;
-(void) addSession:(DkTSession *)session;
-(NSArray *) sessions;

@end

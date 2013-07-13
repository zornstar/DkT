//
//  DkTSession.m
//  DkTp
//
//  Created by Matthew Zorn on 5/26/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSession.h"
#import "DkTUser.h"

@implementation DkTSession
{
    NSNumberFormatter *_formatter;
}

+ (id)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[DkTSession alloc] init];
    });
    return sharedInstance;
}


+(DkTSession *) currentSession
{
    return [DkTSession sharedInstance];
}

+(void) setCurrentSession:(DkTSession *)session
{
    [[DkTSession sharedInstance] setUser:session.user];
    [[DkTSession sharedInstance] setClient:session.client];
    [[DkTSession sharedInstance] setCost:0];
}

- (id)init
{
    self = [super init];
    {
        self.user = [[DkTUser alloc] init];
        self.client = @"";
        _formatter = [[NSNumberFormatter alloc] init];
        [_formatter setNumberStyle:NSNumberFormatterCurrencyStyle];

    }
    return self;
}


+(void) addCost:(float)money
{
    DkTSession *session = [DkTSession sharedInstance];
    session.cost += money;
}

-(void) setUser:(DkTUser *)currentUser
{
    if([currentUser.username isEqualToString:_user.username])
    {
        return;
    }
    
    else
    {
        _user = currentUser;
        
        if([self.delegate respondsToSelector:@selector(didChangeUser:)])
        {
            [self.delegate didChangeUser:_user];
        }
    }
}

+(void) addCostForPages:(NSUInteger)pages
{
    [DkTSession addCost:MAX(pages*.1, 3)];
}

-(void) setCost:(float)cost
{
    _cost = cost;
    _costString = [_formatter stringFromNumber:[NSNumber numberWithFloat:_cost]];
}


@end

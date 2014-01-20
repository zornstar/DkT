
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

@synthesize user = _user;

+ (id)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[DkTSession alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance
                                                 selector:@selector(forceLogout:)
                                                     name:@"forceLogout"
                                                   object:nil];
    });
    return sharedInstance;
}


+(DkTSession *) currentSession
{
    return [DkTSession sharedInstance];
}

+(void) setCurrentSession:(DkTSession *)session
{
    DkTSession *currentSession = [DkTSession sharedInstance];
    [currentSession setUser:session.user];
    [currentSession setClient:session.client];
    [currentSession setCost:0];
}

+(void) nullifyCurrentSession
{
    DkTSession *currentSession = [DkTSession sharedInstance];
    [currentSession setUser:[[DkTUser alloc] init]];
    [currentSession setClient:@""];
    [currentSession setCost:0];
}

- (id)init
{
    self = [super init];
    {
        
        self.client = @"";
        _formatter = [[NSNumberFormatter alloc] init];
        [_formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [_formatter setMinimumFractionDigits:2];
        [_formatter setMaximumFractionDigits:2];

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
    if([currentUser isEqual:self.user])
    {
        return;
    }
   
    _user = currentUser;
        
    if([self.delegate respondsToSelector:@selector(didChangeUser:)])
    {
        [self.delegate didChangeUser:self.user];
    }
}

-(DkTUser *) user
{
    if(_user == nil)
    {
        _user = [[DkTUser alloc] init];
    }
    
    return _user;
}

+(void) addCostForPages:(NSUInteger)pages
{
    [DkTSession addCost:MAX(pages*.1, 3)];
}

-(void) setCost:(float)cost
{
    _cost = cost;
    _costString = [NSString stringWithFormat:@"$   %@",[_formatter stringFromNumber:[NSNumber numberWithFloat:_cost]]];
}

-(void) forceLogout:(id)sender
{
    [self setUser:[[DkTUser alloc] init]];
    [self setClient:@""];
    [self setCost:0];
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

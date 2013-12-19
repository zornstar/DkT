//
//  DkTUserManager.m
//  DkTp
//
//  Created by Matthew Zorn on 6/27/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSessionManager.h"
#import "DkTSession.h"
#import "DkTUser.h"
#import "GDataXMLNode.h"
#import "SSKeychain.h"

@interface DkTSessionManager ()

@property (nonatomic, copy) NSString *filePath;

@end

@implementation DkTSessionManager

+(id)sharedManager
{
    static dispatch_once_t pred;
    static DkTSessionManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[DkTSessionManager alloc] init];
        //NSString* path = [NSSearchPathForDirectoriesInDomains(
        //                                                      NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        //sharedInstance.filePath = [path stringByAppendingPathComponent:@"userlist.xml"];
    });
    return sharedInstance;
}

-(void) addSession:(DkTSession *)session
{
    NSString *account = [NSString stringWithFormat:@"%@::%@", session.user.username, (session.client.length > 0) ? session.client : @""];
    
    [SSKeychain setPassword:session.user.password forService:APP_NAME account:account];
 
    /*
    GDataXMLDocument *doc = [self document];
    
    GDataXMLElement *s = [GDataXMLElement elementWithName:@"session"];
    
    GDataXMLElement *userElement = [GDataXMLElement elementWithName:@"user" stringValue:session.user.username];
    GDataXMLElement *passwordElement = [GDataXMLElement elementWithName:@"password" stringValue:session.user.password];
    GDataXMLElement *clientElement = [GDataXMLElement elementWithName:@"client" stringValue:session.client];
    
    NSArray *children = [doc.rootElement children];
    
    for(GDataXMLElement *child in children)
    {
        NSString *user = [[[child elementsForName:@"user"] lastObject] stringValue];
        NSString *client = [[[child elementsForName:@"client"] lastObject] stringValue];
        
        if([user isEqualToString:session.user.username] && [client isEqualToString:session.client])
        {
            [doc.rootElement removeChild:child];
            break;
        }
    }
    [s addChild:userElement];
    [s addChild:passwordElement];
    [s addChild:clientElement];
    

    if(children.count > 10)
    {
        GDataXMLElement *first = [children firstObject];
        [doc.rootElement removeChild:first];
    }
    
    
    [doc.rootElement addChild:s];
    
    [doc.rootElement.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    */
}
 /*
-(GDataXMLDocument *)document
{
   
    if( ![[NSFileManager defaultManager] fileExistsAtPath:self.filePath])[self create];
    
    NSData *userFile = [NSData dataWithContentsOfFile:self.filePath];
    
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:userFile options:0 error:nil];
    
    return doc;
  
}*/

-(NSArray *) sessions
{
    NSMutableArray *sessions = [NSMutableArray array];
    NSArray *accounts = [SSKeychain accountsForService:APP_NAME];
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy_MM_dd"];
    
    [accounts sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
       
        NSString *str1 = [obj1 objectForKey:kSSKeychainLastModifiedKey];
        NSString *str2 = [obj2 objectForKey:kSSKeychainLastModifiedKey];
        
        NSDate *d1 = [df dateFromString:str1];
        NSDate *d2 = [df dateFromString:str2];
        
        return [d1 compare:d2];
    }];
    
    for(int i = 0; i < accounts.count; ++i)
    {
        NSDictionary *dict = [accounts objectAtIndex:i];
        NSString *account = [dict objectForKey:kSSKeychainAccountKey];
        
        if(i < 4)
        {
            DkTSession *session = [[DkTSession alloc] init];
            NSArray *components = [account componentsSeparatedByString:@"::"];
            session.user.username = components[0];
            session.client = components[1];
            session.user.password = [SSKeychain passwordForService:APP_NAME account:account];
            [sessions addObject:session];
        }
        else
        {
            [SSKeychain deletePasswordForService:APP_NAME account:account];
        }
    }
    
    return sessions;
    
    /*
    GDataXMLDocument *doc = [self document];
    NSMutableArray *items = [NSMutableArray array];
    
    for(GDataXMLElement *s in [doc.rootElement children])
    {
        DkTSession *session = [[DkTSession alloc] init];
        NSArray *children = [s children];
        
        if(children.count > 0)
        {
            for(GDataXMLElement *property in children)
            {
                if([property.name isEqualToString:@"user"])
                {
                    session.user.username = property.stringValue;
                }
                
                else if ([property.name isEqualToString:@"password"])
                {
                    session.user.password = property.stringValue;
                }
                
                else if ([property.name isEqualToString:@"client"])
                {
                    session.client = property.stringValue;
                }
                
            }
            
            [items insertObject:session atIndex:0];
        }
        
    }
    
    return items;
     */
}

+(DkTSession *) lastSession
{
    return [[[DkTSessionManager sharedManager] sessions] firstObject];
    /*
    GDataXMLDocument *doc = [[DkTSession sharedInstance] document];
    DkTSession *session = [[DkTSession alloc] init];
    GDataXMLElement *element = [[doc.rootElement children] objectAtIndex:0];
    
    for(GDataXMLElement *property in [element children])
    {
        if([property.name isEqualToString:@"user"])
        {
            session.user.username = property.stringValue;
        }
        
        else if ([property.name isEqualToString:@"password"])
        {
            session.user.password = property.stringValue;
        }
        
        else if ([property.name isEqualToString:@"client"])
        {
            session.client = property.stringValue;
        }
    }
    
    return session;*/
}

/*
-(void) create
{
    GDataXMLElement *root = [GDataXMLElement elementWithName:@"sessions"];
    [root.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                                              forKey:NSFileProtectionKey] ofItemAtPath:self.filePath error:nil];
    return;
}*/


@end

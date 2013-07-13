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
        NSString* path = [NSSearchPathForDirectoriesInDomains(
                                                              NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        sharedInstance.filePath = [path stringByAppendingPathComponent:@"userlist.xml"];
    });
    return sharedInstance;
}

-(void) addSession:(DkTSession *)session
{
    
    GDataXMLDocument *doc = [self document];
    
    GDataXMLElement *s = [GDataXMLElement elementWithName:@"session"];
    
    GDataXMLElement *userElement = [GDataXMLElement elementWithName:@"user" stringValue:session.user.username];
    GDataXMLElement *passwordElement = [GDataXMLElement elementWithName:@"password" stringValue:session.user.password];
    GDataXMLElement *clientElement = [GDataXMLElement elementWithName:@"client" stringValue:session.client];
    
    [s addChild:userElement];
    [s addChild:passwordElement];
    [s addChild:clientElement];
    
    [doc.rootElement addChild:s];
    [doc.rootElement.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(GDataXMLDocument *)document
{
    if( ![[NSFileManager defaultManager] fileExistsAtPath:self.filePath])[self create];
    
    NSData *userFile = [NSData dataWithContentsOfFile:self.filePath];
    
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:userFile options:0 error:nil];
    
    return doc;
}

-(NSArray *) sessions
{
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
            
            [items addObject:session];
        }
        
    }
    
    return items;
}

-(void) create
{
    GDataXMLElement *root = [GDataXMLElement elementWithName:@"sessions"];
    [root.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return;
}

@end

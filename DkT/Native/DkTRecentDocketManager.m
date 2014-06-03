//
//  DkTRecentDocketManager.m
//  DkT
//
//  Created by Matthew Zorn on 3/21/14.
//  Copyright (c) 2014 Matthew Zorn. All rights reserved.
//

#import "DkTRecentDocketManager.h"
#import "DkTDocumentManager.h"
#import "GDataXMLNode.h"

#define MAX_RECENT_ENTRIES 10

@implementation DkTRecentDocketManager

+ (id)sharedManager
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        NSString* path = [DkTDocumentManager applicationDocumentsDirectory];
        path = [path stringByAppendingPathComponent:@"DkTRecentDockets.xml"];
        sharedInstance = [[DkTBookmarkManager alloc] initWithBookmarkFile:path];
    });
    return sharedInstance;
}

+(NSString *) bookmarkPath:(DkTDocket *)docket {
    return [NSString stringWithFormat:@"%@/Recent/%@-%@.%@", [DkTBookmarkManager bookmarkFolder],docket.case_num,docket.court,@"xml"];
}

-(void) create
{
    GDataXMLElement *root = [GDataXMLElement elementWithName:@"recent"];
    [root.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return;
}

-(GDataXMLDocument *) addBookmark:(DkTDocket *)item
{
    
    GDataXMLDocument *doc = [self document];
    
    NSArray *children = [doc.rootElement children];
    
    for(GDataXMLElement *child in children)
    {
        GDataXMLElement *uElement = [[child elementsForName:@"url"] lastObject];
        
        if([item.link isEqualToString:uElement.stringValue]) return doc;
    }
    
    GDataXMLElement *bookmark = [self elementWithDocket:item];
    
    [doc.rootElement addChild:bookmark];
    
    if (children.count >= 11) [doc.rootElement removeChild:[children lastObject]];
    
    [doc.rootElement.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    if([self.delegate respondsToSelector:@selector(didAddBookmark:)])
    {
        [self.delegate didAddBookmark:item];
    }
    
    return doc;
}

@end

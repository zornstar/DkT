//
//  DkTBookmarkManager.m
//  DkTp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTBookmarkManager.h"
#import "DkTBookmark.h"
#import "DkTConstants.h"
#import "GDataXMLNode.h"
#import "DkTDocket.h"
#import "DkTDocketEntry.h"
#import "DkTDocumentManager.h"

NSString* const DkTBookmarkDocketNameKey = @"name";
NSString* const DkTBookmarkDocketUpdateKey = @"updated";
NSString* const DkTBookmarkDocketEntriesKey = @"entries";

@implementation DkTBookmarkManager

+ (id)sharedManager
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        
        NSString* path = [NSSearchPathForDirectoriesInDomains(
                                                              NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        path = [path stringByAppendingPathComponent:@"DkTbookmarks.xml"];
        sharedInstance = [[DkTBookmarkManager alloc] initWithBookmarkFile:path];
    });
    return sharedInstance;
}


-(id) initWithBookmarkFile:(NSString *)filePath
{
    if(self = [super init])
    {
        _filePath = filePath;
        [self document]; //create if does not exist
    }
    
    return self;
}


-(GDataXMLDocument *)document
{
    if( ![[NSFileManager defaultManager] fileExistsAtPath:self.filePath])[self create];
    
    NSData *bookmarkFile = [NSData dataWithContentsOfFile:self.filePath];
    
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:bookmarkFile options:0 error:nil];
    
    return doc;
}

-(void) addBookmark:(DkTDocket *)item
{
    
    GDataXMLDocument *doc = [self document];
    
    NSArray *children = [doc.rootElement children];
    
    for(GDataXMLElement *child in children)
    {
        GDataXMLElement *uElement = [[child elementsForName:@"url"] lastObject];
        
        if([item.link isEqualToString:uElement.stringValue]) return;
    }
    
    
    GDataXMLElement *bookmark = [GDataXMLElement elementWithName:@"bookmark"];
    
    GDataXMLElement *nameElement = [GDataXMLElement elementWithName:@"name" stringValue:item.name];
    GDataXMLElement *urlElement = [GDataXMLElement elementWithName:@"url" stringValue:item.link];
    GDataXMLElement *courtElement = [GDataXMLElement elementWithName:@"court" stringValue:item.court];
    GDataXMLElement *dateElement = [GDataXMLElement elementWithName:@"date" stringValue:item.date];
    
    [bookmark addChild:nameElement];
    [bookmark addChild:urlElement];
    [bookmark addChild:courtElement];
    [bookmark addChild:dateElement];
    
    [doc.rootElement addChild:bookmark];
    [doc.rootElement.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    if([self.delegate respondsToSelector:@selector(didAddBookmark:)])
    {
        [self.delegate didAddBookmark:item];
    }
}

-(void) create
{
    GDataXMLElement *root = [GDataXMLElement elementWithName:@"bookmarks"];
    [root.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return;
}

-(BOOL) deleteBookmark:(NSString *)urlString
{
    GDataXMLDocument *doc = [self document];
    
    NSArray *children = [doc.rootElement children];
    
    for(GDataXMLElement *child in children)
    {
        NSArray *properties = [child children];
        
        for(GDataXMLElement *property in properties)
        {
            if([property.name isEqualToString:@"url"] && [property.stringValue isEqualToString:urlString])
            {
                [doc.rootElement removeChild:child];
                return TRUE;
            }
        }
    }
    
    return FALSE;
}

-(BOOL) deleteBookmarkItem:(DkTDocket *)docket
{
    return [self deleteBookmark:docket.link];
}

-(void) clearAllBookmarks
{
    [self create];
}

-(NSArray *)bookmarks
{
    GDataXMLDocument *doc = [self document];
    NSMutableArray *items = [NSMutableArray array];
    
    NSArray *bookmarks = [doc.rootElement children];
    
    for(GDataXMLElement *bookmark in bookmarks)
    {
        DkTDocket *item = [[DkTDocket alloc] init];
        NSArray *children = [bookmark children];
        
        if(children.count > 0)
        {
            for(GDataXMLElement *property in children)
            {
                if([property.name isEqualToString:@"name"])
                {
                    item.name = property.stringValue;
                }
                
                else if ([property.name isEqualToString:@"url"])
                {
                    item.link = property.stringValue;
                }
                
                else if ([property.name isEqualToString:@"court"])
                {
                    item.court = property.stringValue;
                }
                
                else if ([property.name isEqualToString:@"date"])
                {
                    item.date = property.stringValue;
                }
                
            }
            
            [items addObject:item];
        }
        
    }
    
    return items;
}

/*
-(void) writeItems:(NSArray *)items
{
    GDataXMLDocument *doc = [self document];
    
    for(H2OItem *item in items)
    {
        GDataXMLElement *bookmark = [GDataXMLElement elementWithName:@"bookmark"];
        
        GDataXMLElement *nameElement = [GDataXMLElement elementWithName:@"name" stringValue:item.name];
        GDataXMLElement *urlElement = [GDataXMLElement elementWithName:@"url" stringValue:item.link];
        GDataXMLElement *type = [GDataXMLElement elementWithName:@"type" stringValue:[NSString stringWithFormat:@"%d", item.itemType]];
        
        [bookmark addChild:nameElement];
        [bookmark addChild:urlElement];
        [bookmark addChild:type];
        
        [doc.rootElement addChild:bookmark];
    }
    
    [doc.rootElement.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}*/

-(void) bookmarkDocket:(DkTDocket *)docket withDocketEntries:(NSArray *)docketEntries
{
    [self addBookmark:docket];
    
    GDataXMLElement *root = [GDataXMLElement elementWithName:@"docket"];
    
    GDataXMLElement *name = [GDataXMLElement elementWithName:DkTBookmarkDocketNameKey stringValue:docket.name];
    
    [root addChild:name];
    
    GDataXMLElement *lastUpdated = [GDataXMLElement elementWithName:DkTBookmarkDocketUpdateKey stringValue:[[NSDate date] description]];
    
    [root addChild:lastUpdated];
    
    GDataXMLElement *entries = [GDataXMLElement elementWithName:DkTBookmarkDocketEntriesKey];
    
    if(docketEntries.count > 0)
    {
        NSArray *keys = [((DkTDocketEntry *)[docketEntries objectAtIndex:0]) properties];
        
        for(DkTDocketEntry *entry in docketEntries)
        {
            GDataXMLElement *entryElement = [GDataXMLElement elementWithName:@"entry"];
            
            for(NSString *key in keys)
            {
                GDataXMLElement *element = [GDataXMLElement elementWithName:key];
                
                id value = [entry valueForKey:key];
                
                if ([value isKindOfClass:[NSString class]])
                {
                    element.stringValue = value;
                    [entryElement addChild:element];
                }
                
            }
            
            [entries addChild:entryElement];
        }
    }//end docket entries
    
    [root addChild:entries];
    
    NSString *path = [[[docket folder] stringByAppendingString:docket.case_num] stringByAppendingString:@".xml"];
    
    [root.XMLString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
}

-(NSDictionary *) savedDocket:(DkTDocket *)docket
{
    NSString *path = [[[docket folder] stringByAppendingString:docket.case_num] stringByAppendingString:@".xml"];
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data options:0 error:nil];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    
    GDataXMLElement *name = [[doc.rootElement elementsForName:DkTBookmarkDocketNameKey] objectAtIndex:0];
    
    [dict setObject:name.stringValue forKey:DkTBookmarkDocketNameKey];
    
    GDataXMLElement *updated = [[doc.rootElement elementsForName:DkTBookmarkDocketEntriesKey] objectAtIndex:0];
    [dict setObject:updated.stringValue forKey:DkTBookmarkDocketUpdateKey];
    
    GDataXMLElement *entryRoot = [[doc.rootElement elementsForName:DkTBookmarkDocketEntriesKey] objectAtIndex:0];
    
    NSArray *entriesElements = [entryRoot elementsForName:@"entry"];
    
    NSArray *keys = [[[DkTDocketEntry alloc] init] properties];
    
    NSMutableArray *entries = [NSMutableArray array];
    
    for(GDataXMLElement *entry in entriesElements)
    {
        DkTDocketEntry *e = [[DkTDocketEntry alloc] init];
        
        for(GDataXMLElement *property in entry.children)
        {
            if([keys containsObject:property.name])
            {
                [e setValue:property.stringValue forKey:property.name];
            }
        }
        
        [entries addObject:e];
    }
    
    [dict setObject:entries forKey:DkTBookmarkDocketEntriesKey];
    
    
    return dict;
    
}



@end

//
//  DkTBookmarkManager.m
//  DkTp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTBookmarkManager.h"
#import "DkTConstants.h"
#import "GDataXMLNode.h"
#import "DkTDocket.h"
#import "DkTDocketEntry.h"
#import "DkTDocumentManager.h"
#import "PACERClient.h"
#import <CoreText/CoreText.h>
#import <objc/runtime.h>

NSString* const DkTBookmarkDocketNameKey = @"name";
NSString* const DkTBookmarkDocketUpdateKey = @"updated";
NSString* const DkTBookmarkDocketEntriesKey = @"entries";


@implementation DkTBookmarkManager

+ (id)sharedManager
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        
        NSString* path = [DkTDocumentManager applicationDocumentsDirectory];
        
        path = [path stringByAppendingPathComponent:@"DkTBookmarks.xml"];
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

+(NSString *)bookmarkFolder
{
    return [DkTDocumentManager docketsFolder];
}

-(GDataXMLElement *) elementWithDocketEntry:(DkTDocketEntry *)entry
{
    GDataXMLElement *entryElement = [GDataXMLElement elementWithName:@"entry"];
    
    for (int i=0; i < SIZE_OF_WRITEABLE_PROPERTIES; i++) {
        NSString *key = kWriteableProperties[i];
        GDataXMLElement *element = [GDataXMLElement elementWithName:key];
        
        id value = [entry valueForKey:key];
        
        if([value isKindOfClass:[NSString class]]) element.stringValue = value;
        
        else if([value isKindOfClass:[NSNumber class]]) element.stringValue = [value stringValue];
        
        else if([value isKindOfClass:[NSMutableDictionary class]])
        {
            NSArray *dictkeys = [((NSMutableDictionary *)value) allKeys];
            
            for(NSString *k in dictkeys)
            {
                GDataXMLElement *dictelement = [GDataXMLElement elementWithName:k];
                NSString *v = [value objectForKey:k];
                dictelement.stringValue = [v stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
                [element addChild:dictelement];
                
                /* GDataXMLElement *dictelement = [GDataXMLElement elementWithName:k];
                 NSString *v = [value objectForKey:k];
                 dictelement.stringValue = [v gtm_stringBySanitizingAndEscapingForXML];
                 [element addChild:dictelement];*/
            }
        }
        
        [entryElement addChild:element];
        
    }
    
    return entryElement;
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
    GDataXMLElement *case_num = [GDataXMLElement elementWithName:@"case_num" stringValue:item.case_num];
    GDataXMLElement *cs_caseid = [GDataXMLElement elementWithName:@"cs_caseid" stringValue:item.cs_caseid];
    GDataXMLElement *nameElement = [GDataXMLElement elementWithName:@"name" stringValue:item.name];
    GDataXMLElement *urlElement = [GDataXMLElement elementWithName:@"url" stringValue:item.link];
    GDataXMLElement *courtElement = [GDataXMLElement elementWithName:@"court" stringValue:item.court];
    GDataXMLElement *dateElement = [GDataXMLElement elementWithName:@"date" stringValue:item.date];
    GDataXMLElement *updateElement = [GDataXMLElement elementWithName:@"updated" stringValue:item.updated];
    
    [bookmark addChild:nameElement];
    [bookmark addChild:cs_caseid];
    [bookmark addChild:case_num];
    [bookmark addChild:urlElement];
    [bookmark addChild:courtElement];
    [bookmark addChild:dateElement];
    [bookmark addChild:updateElement];
    
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
                [doc.rootElement.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                return TRUE;
            }
        }
    }
    
    return FALSE;
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
                if ([property.name isEqualToString:@"case_num"])
                {
                    item.case_num = property.stringValue;
                }
                
                else if([property.name isEqualToString:@"name"])
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
                
                else if ([property.name isEqualToString:@"updated"])
                {
                    item.updated = property.stringValue;
                }
                
            }
            
            [items addObject:item];
        }
        
    }
    
    return items;
}

-(void) bookmarkDocket:(DkTDocket *)docket withDocketEntries:(NSArray *)docketEntries
{
    [self addBookmark:docket];
    
    GDataXMLElement *root = [GDataXMLElement elementWithName:@"docket"];
    
    GDataXMLElement *name = [GDataXMLElement elementWithName:DkTBookmarkDocketNameKey stringValue:docket.name];
    
    [root addChild:name];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    
    GDataXMLElement *lastUpdated = [GDataXMLElement elementWithName:DkTBookmarkDocketUpdateKey stringValue:[dateFormatter stringFromDate:[NSDate date]]];
    
    [root addChild:lastUpdated];
    
    GDataXMLElement *entries = [GDataXMLElement elementWithName:DkTBookmarkDocketEntriesKey];
    
    if(docketEntries.count > 0)
    {
        
        for(DkTDocketEntry *entry in docketEntries)
        {
            
            @autoreleasepool {
                
                GDataXMLElement *element = [self elementWithDocketEntry:entry];
                [entries addChild:element];
                
            }
            
        }
    }//end docket entries
    
    [root addChild:entries];
    
    if( ![[NSFileManager defaultManager] fileExistsAtPath:[DkTBookmarkManager bookmarkFolder] isDirectory:nil])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:[DkTBookmarkManager bookmarkFolder] withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *path = [NSString stringWithFormat:@"%@/%@.%@", [DkTBookmarkManager bookmarkFolder],docket.case_num,@"xml"];
    
    [root.XMLString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
}

-(NSArray *) savedDocket:(DkTDocket *)docket
{
 
    @autoreleasepool {
        
        NSString *path = [NSString stringWithFormat:@"%@/%@.%@", [DkTBookmarkManager bookmarkFolder],docket.case_num,@"xml"];
        
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data options:0 error:nil];
        
        
        GDataXMLElement *name = [[doc.rootElement elementsForName:DkTBookmarkDocketNameKey] objectAtIndex:0];
        docket.name = [name.stringValue copy];
        name = nil;
        
        GDataXMLElement *updated = [[doc.rootElement elementsForName:DkTBookmarkDocketUpdateKey] objectAtIndex:0];
        docket.updated = [updated.stringValue copy];
        updated = nil;
        
        GDataXMLElement *entryRoot = [[doc.rootElement elementsForName:DkTBookmarkDocketEntriesKey] objectAtIndex:0];
        
        NSArray *entriesElements = [entryRoot elementsForName:@"entry"];
        
        NSMutableArray *keys = [[NSMutableArray alloc] init];
        
        for(int i = 0; i < SIZE_OF_WRITEABLE_PROPERTIES; ++i)
        {
            [keys addObject:kWriteableProperties[i]];
        }
        
        NSMutableArray *entries = [NSMutableArray array];
        
        for(GDataXMLElement *entry in entriesElements)
        {
            @autoreleasepool {
                
                DkTDocketEntry *e = [[DkTDocketEntry alloc] init];
                
                for(GDataXMLElement *property in entry.children)
                {
                    @autoreleasepool {
                        
                        if([keys containsObject:property.name])
                        {
                            objc_property_t prop = class_getProperty([DkTDocketEntry class], [property.name UTF8String]);
                            NSString * propertyAttrs = [NSString stringWithUTF8String:property_getAttributes(prop)];
                            
                            if([propertyAttrs rangeOfString:@"String"].location != NSNotFound)
                            {
                               [e setValue:property.stringValue forKey:property.name];
                            }
                            else if([propertyAttrs rangeOfString:@"Number"].location != NSNotFound)
                            {
                                int i = [property.stringValue intValue];
                                [e setValue:[NSNumber numberWithInt:i] forKey:property.name];
                            }
                            
                            else if([propertyAttrs rangeOfString:@"Dictionary"].location != NSNotFound)
                            {
                                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                                
                                for(GDataXMLElement *dictKey in [property children])
                                {
                                    [dict setObject:[[dictKey.stringValue copy] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"] forKey:dictKey.name];
                                }
                                
                                [e setValue:dict forKey:property.name];
                            }
                            
                            
                        }
                        
                        
                    }
                }
                
                e.docket = docket;
                [entries addObject:e];
                
            }
            
        }
        
        entryRoot = nil;
        doc = nil;
        entriesElements = nil;
        
        return entries;
    }
   
}

-(BOOL) updateBookmark:(DkTDocket *)item
{
    GDataXMLDocument *doc = [self document];
    
    NSArray *children = [doc.rootElement children];
    
    for(GDataXMLElement *child in children)
    {
        GDataXMLElement *uElement = [[child elementsForName:@"url"] lastObject];
        
        if([item.link isEqualToString:[uElement.stringValue copy]])
        {
            
            GDataXMLElement *updatedElement = [[child elementsForName:@"updated"] lastObject];
            updatedElement.stringValue = item.updated;
            
            [doc.rootElement.XMLString writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            return TRUE;
        }
    }
    
    return FALSE;
    
}

-(NSInteger) appendEntries:(NSArray *)entries toSavedDocket:(DkTDocket *)docket
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@.%@", [DkTBookmarkManager bookmarkFolder],docket.case_num,@"xml"];
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data options:0 error:nil];
    
    GDataXMLElement *updateElement = [[doc.rootElement elementsForName:DkTBookmarkDocketUpdateKey] objectAtIndex:0];
    updateElement.stringValue = [dateFormatter stringFromDate:[NSDate date]];
    GDataXMLElement *entryRoot = [[doc.rootElement elementsForName:DkTBookmarkDocketEntriesKey] objectAtIndex:0];
    
    GDataXMLElement *updated = [[doc.rootElement elementsForName:DkTBookmarkDocketUpdateKey] objectAtIndex:0];
    [doc.rootElement removeChild:updated];
    updated = [GDataXMLElement elementWithName:DkTBookmarkDocketUpdateKey stringValue:[dateFormatter stringFromDate:[NSDate date]]];
    [doc.rootElement addChild:updated];
    
    if(entries.count == 0){
        [self updateBookmark:docket];
        return 0;
    }
    
    NSArray *xmlentries = [entryRoot children];
    
    GDataXMLElement *lastChild = [xmlentries lastObject];
    
    NSString *lastEntryDate = [[[lastChild elementsForName:@"date"] firstObject] stringValue];
    NSString *lastSummary = [[[lastChild elementsForName:@"summary"] firstObject] stringValue];

    DkTDocketEntry *_e = [entries objectAtIndex:0];
    
    NSDate *date1 = [dateFormatter dateFromString:_e.date];
    NSDate *date2 = [dateFormatter dateFromString:lastEntryDate];
    
    int idx = 0;
    
    if ([date1 compare:date2] == NSOrderedAscending)
    {
        [self updateBookmark:docket];
        return 0;
    }
    //allow
    else if ([date1 compare:date2] == NSOrderedSame){
        
        for(int i = 0; i < entries.count; ++i)
        {
            _e = [entries objectAtIndex:i];
            
            if([_e.summary isEqualToString:lastSummary])
            {
                idx = i+1;
                break;
            }
            
            
        }
    }
    
    for(int i = idx; i < entries.count; ++i)
    {
        GDataXMLElement *element = [self elementWithDocketEntry:entries[i]];
        [entryRoot addChild:element];
    }
    
    [doc.rootElement.XMLString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [self updateBookmark:docket];
    return entries.count - idx;
}

-(void) updateBookmarks:(NSArray *)items
{
    for(DkTDocket *docket in items)
    {
        PACERClient *client = [[PACERClient alloc] init];
        
        [client retrieveDocket:docket sender:self to:@"" from:docket.updated];
    }
}

-(void) handleDocket:(DkTDocket *)docket entries:(NSArray *)entries to:(NSString *)to from:(NSString *)from
{
    NSInteger n = [[DkTBookmarkManager sharedManager] appendEntries:entries toSavedDocket:docket];
    
    if([self.delegate respondsToSelector:@selector(addBadgeToDocket:number:)])
    {
        [self.delegate addBadgeToDocket:docket number:n];
    }
}
@end


//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PACERClient.h"

@class DkTDocket, GDataXMLDocument, GDataXMLElement;

@protocol DkTBookmarkManagerDelegate <NSObject>

-(void) didAddBookmark:(DkTDocket *)docket;
-(void) addBadgeToDocket:(DkTDocket *)docket number:(int)number;

@end

@interface DkTBookmarkManager : NSObject <PACERClientProtocol>

extern NSString* const DkTBookmarkDocketNameKey;
extern NSString* const DkTBookmarkDocketUpdateKey;
extern NSString* const DkTBookmarkDocketEntriesKey;

@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, weak) id<DkTBookmarkManagerDelegate> delegate;

-(id) initWithBookmarkFile:(NSString *)filePath;


+(id) sharedManager;
+(NSString *)bookmarkFolder;
-(GDataXMLDocument *)document;
-(GDataXMLDocument *) addBookmark:(DkTDocket *)item;
-(BOOL) updateBookmark:(DkTDocket *)item;
-(void) updateBookmarks:(NSArray *)items;
-(BOOL) deleteBookmark:(DkTDocket *)item;
-(void) moveBookmark:(DkTDocket *)item toIndex:(NSUInteger)index;
-(NSArray *)bookmarks;
-(void) write;
-(NSArray *)savedDocket:(DkTDocket *)docket;
-(void) bookmarkDocket:(DkTDocket *)docket withDocketEntries:(NSArray *)docketEntries;
-(NSInteger) appendEntries:(NSArray *)entries toSavedDocket:(DkTDocket *)docket;
-(GDataXMLElement *) elementWithDocket:(DkTDocket *)item;
-(DkTDocket *) docketWithElement:(GDataXMLElement *)element;
-(NSString *) bookmarkPath:(DkTDocket *)docket;
//-(NSString *) drawDocketSheet:(DkTDocket *)docket;



@end

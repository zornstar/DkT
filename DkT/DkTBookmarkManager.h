//
//  DkTBookmarkManager.h
//  DkTp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PACERClient.h"

@class DkTDocket;

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

-(void) addBookmark:(DkTDocket *)item;
-(BOOL) updateBookmark:(DkTDocket *)item;
-(void) updateBookmarks:(NSArray *)items;
-(BOOL) deleteBookmark:(NSString *)urlString;
-(void) clearAllBookmarks;
-(NSArray *)bookmarks;
-(NSArray *)savedDocket:(DkTDocket *)docket;
-(void) bookmarkDocket:(DkTDocket *)docket withDocketEntries:(NSArray *)docketEntries;
-(NSInteger) appendEntries:(NSArray *)entries toSavedDocket:(DkTDocket *)docket;
//-(NSString *) drawDocketSheet:(DkTDocket *)docket;



@end

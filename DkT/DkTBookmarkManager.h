//
//  DkTBookmarkManager.h
//  DkTp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DkTDocket;

@protocol DkTBookmarkManagerDelegate <NSObject>

-(void) didAddBookmark:(DkTDocket *)docket;

@end

@interface DkTBookmarkManager : NSObject

extern NSString* const DkTBookmarkDocketNameKey;
extern NSString* const DkTBookmarkDocketUpdateKey;
extern NSString* const DkTBookmarkDocketEntriesKey;

@property (nonatomic, copy, readonly) NSString *filePath;
@property (unsafe_unretained) id<DkTBookmarkManagerDelegate> delegate;

-(id) initWithBookmarkFile:(NSString *)filePath;
+(id) sharedManager;

-(void) addBookmark:(DkTDocket *)item;
-(BOOL) deleteBookmark:(NSString *)urlString;
-(BOOL) deleteBookmarkItem:(DkTDocket *)item;
-(void) clearAllBookmarks;
-(NSArray *)bookmarks;
-(void) writeItems:(NSArray *)items;
-(void) bookmarkDocket:(DkTDocket *)docket withDocketEntries:(NSArray *)docketEntries;


@end

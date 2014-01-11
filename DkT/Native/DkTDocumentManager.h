//
//  DkTDocumentManager.h
//  DkTp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const DkTFileEntryKey;
extern NSString* const DkTFileSummaryKey;
extern NSString* const DkTFilePathKey;
extern NSString* const DkTFileDocketNameKey;
extern NSString* const DkTFileDocketFilesKey;
extern NSString* const DkTFileDocketCollapsedKey;

typedef NS_OPTIONS(NSUInteger, DkTBatchOptions) {
    DkTBatchOptionsNone = 0,
    DkTBatchOptionsPageNumbers = (1 << 0),
    DkTBatchOptionsTOC = (1 << 1)
};

#define DkTFileCreate(_entry, _summary, _path) @{DkTFileEntryKey:_entry, DkTFileSummaryKey:_summary, DkTFilePathKey:_path}
#define DkTDocketFileCreate(_name) [@{DkTFileDocketNameKey:_name, DkTFileDocketFilesKey:[NSMutableArray array], DkTFileDocketCollapsedKey:@TRUE} mutableCopy]

@class DkTDocket, DkTDocketEntry;

typedef void (^DkTLocalDocumentBlock)(id entry, id filepath);
typedef void (^DkTBatchCompletionBlock)(id filepath);
typedef NSDictionary DkTFile;
typedef NSMutableDictionary DkTDocketFile;

@protocol DkTDocumentManagerDelegate <NSObject>

@optional

-(void) didSaveFile:(DkTFile *)file;
-(void) didStartCloudSync:(NSNotification *)notification;

@end

@interface DkTDocumentManager : NSObject


@property (nonatomic) BOOL iCloud;

+(id)sharedManager;
+(NSString *) applicationDirectory;
+(NSString *) applicationDocumentsDirectory;
+(NSString *) temporaryDocumentsDirectory;
+(NSString *) docketsFolder;
+(NSString *) pathToDocket:(NSString *)docketName;
+(NSString *) helpDocumentPath;
+(void)joinDocketNamed:(NSString *)docketName destination:(NSString *)path batchOptions:(DkTBatchOptions)options completion:(DkTBatchCompletionBlock)blk;
+(NSString *) saveDocumentAtTempPath:(NSString *)tempPath toSavedDocketNamed:(NSString *)name;
+(void) clearTempFiles;
+(NSString *) localPathForDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry;
+(void) localPathForDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry completion:(DkTLocalDocumentBlock)blk;
+(void) setDelegate:(id<DkTDocumentManagerDelegate>)delegate;
+(NSString *) zipDocketAtPath:(NSString *)filePath;
+(NSString *) saveDocketEntry:(DkTDocketEntry *)entry atTempPath:(NSString *)tempPath;

-(void) sync;
-(void) removeFile:(DkTFile *)file;
-(void) addFile:(DkTFile *)file;
-(void) removeDocketNamed:(NSString *)docketName;

@end
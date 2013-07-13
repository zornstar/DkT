//
//  DkTDocumentManager.h
//  DkTp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DkTDocket, DkTDocketEntry;

typedef void (^DkTLocalDocumentBlock)(id entry, id filepath);

@protocol DkTDocumentManagerDelegate <NSObject>

@optional

-(void) didSaveDocumentAtPath:(NSString *)path;

@end

@interface DkTDocumentManager : NSObject

+(NSString *) applicationDirectory;
+(NSString *) applicationDocumentsDirectory;
+(NSString *) temporaryDocumentsDirectory;
+(NSArray *) documentNamesInDocket:(DkTDocket *)docket;
+(NSArray *) dockets;
+(NSString *) docketsFolder;
+(NSString *) pathToDocket:(NSString *)docketName;

+(NSString *) saveDocumentAtTempPath:(NSString *)tempPath toSavedDocket:(DkTDocket *)docket;
+(void) clearTempFiles;
+(NSString *) localPathForDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry;
+(void) localPathForDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry completion:(DkTLocalDocumentBlock)blk;

+(void) setDelegate:(id<DkTDocumentManagerDelegate>)delegate;

@end
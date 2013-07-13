//
//  DkTDocumentManager.m
//  DkTp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDocumentManager.h"
#import "DkTDocket.h"
#import "DkTDocketEntry.h"

@interface DkTDocumentManager ()

@property (unsafe_unretained) id<DkTDocumentManagerDelegate> delegate;

@end

@implementation DkTDocumentManager

+(id)sharedManager
{
    static dispatch_once_t pred;
    static DkTDocumentManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[DkTDocumentManager alloc] init];
        sharedInstance.delegate = nil;
    });
    return sharedInstance;
}

+(void) setDelegate:(id<DkTDocumentManagerDelegate>)delegate
{
    [[DkTDocumentManager sharedManager] setDelegate:delegate];
}

+(NSString *)applicationDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSUserDomainMask, YES) lastObject];
}

+(NSString *) applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+(NSString *) docketsFolder
{
    return [[DkTDocumentManager applicationDocumentsDirectory] stringByAppendingPathComponent:kDocketsFolder];
}

+(NSArray *) dockets
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *docketPath = [DkTDocumentManager docketsFolder];
    NSArray *dirContents = [manager contentsOfDirectoryAtPath:docketPath error:nil];
    
    NSMutableArray *array = [NSMutableArray array];
    
    for(NSString *folder in dirContents)
    {
        
        BOOL isDir;
        if([manager fileExistsAtPath:[docketPath stringByAppendingPathComponent:folder] isDirectory:&isDir])
        {
            if (isDir) [array addObject:folder];
        }
    }
    
    return array;
}

+(NSArray *) documentNamesInDocket:(DkTDocket *)docket
{
    NSString *docketFolderPath = [docket folder];
    
    NSMutableArray *returnArray = [NSMutableArray array];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docketFolderPath error:nil];
    
    for (NSString *filename in dirContents) {
        if ([filename hasSuffix:@".pdf"]) {
            
            [returnArray addObject:filename];
        }
    }
    
    return returnArray;
}
+(NSString *)temporaryDocumentsDirectory
{
    return NSTemporaryDirectory();
}

+(void) clearTempFiles
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSArray *fileArray = [manager contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    
    for (NSString *filename in fileArray)  {
        
        [manager removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:filename] error:NULL];
    }
    
}

+(NSString *)saveDocumentAtTempPath:(NSString *)tempPath toSavedDocket:(DkTDocket *)docket
{
    NSFileManager *manager = [NSFileManager defaultManager];
     NSError *error;
    
    NSString *folderName = docket.name;
    NSString *fileName = [tempPath lastPathComponent];
    
    NSString *docketPath = [DkTDocumentManager docketsFolder];
    
    NSLog(@"%@", docketPath);
    
    if (![manager fileExistsAtPath:docketPath])
        [manager createDirectoryAtPath:docketPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create base folder
    
    
    docketPath = [docketPath stringByAppendingPathComponent:folderName];
    
    NSLog(@"%@", docketPath);
    
    if (![manager fileExistsAtPath:docketPath])
        [manager createDirectoryAtPath:docketPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    
    
    docketPath = [docketPath stringByAppendingPathComponent:fileName];
    
    [manager copyItemAtPath:tempPath toPath:docketPath error:&error];
    
    if(error) return nil;
    
    else
    {
        id<DkTDocumentManagerDelegate> delegate = [[DkTDocumentManager sharedManager] delegate];
        
        if([delegate respondsToSelector:@selector(didSaveDocumentAtPath:)])
        {
            [delegate didSaveDocumentAtPath:docketPath];
        }
        
        return docketPath;
    }
}

+(NSString *) localPathForDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *docketFolder = [docket folder];
    NSString *pathToEntry = [docketFolder stringByAppendingString:[entry fileName]];
    
    if([manager fileExistsAtPath:pathToEntry]) return pathToEntry;
    
    else return nil;
    
}

+(void) localPathForDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry completion:(DkTLocalDocumentBlock)blk
{
    NSString *path = [DkTDocumentManager localPathForDocket:docket entry:entry];
    
    blk(entry, path);
}

+(NSString *)pathToDocket:(NSString *)docketName
{
    return [[self docketsFolder] stringByAppendingPathComponent:docketName];
}

@end

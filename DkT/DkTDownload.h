//
//  DkTBatchDownload.h
//  DkT
//
//  Created by Matthew Zorn on 10/6/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum  {
    DkTDownloadCompletionStatusNone = 0,
    DkTDownloadCompletionStatusError = 1,
    DkTDownloadCompletionStatusPartial = 2,
    DkTDownloadCompletionStatusComplete = 3
} DkTDownloadCompletionStatus;


@class DkTDocketEntry, DKTAttachment, DkTDownload;

typedef void (^DkTDownloadCompletionBlock)(DkTDownload *download, DkTDownloadCompletionStatus status);


@interface DkTDownload : NSObject

-(id) initWithCompletionBlock:(DkTDownloadCompletionBlock)cBlock;
-(id) initWithEntry:(DkTDocketEntry *)entry completionBlock:(DkTDownloadCompletionBlock)cBlock;
-(DkTDownload *) downloadForEntry:(DkTDocketEntry *)entry;
-(DkTDownloadCompletionStatus) updateCompletionStatus;
-(void) addEntries:(NSArray *)attachments completionBlock:(DkTDownloadCompletionBlock)cBlock;

@property (nonatomic, strong) DkTDocketEntry *entry;
@property (nonatomic) DkTDownloadCompletionStatus status;
@property (nonatomic, copy) DkTDownloadCompletionBlock completionBlock;
@property (nonatomic, strong) NSArray *children;
@property (nonatomic, weak) DkTDownload *parent;
@property (nonatomic) NSInteger completedChildren;

@end


    

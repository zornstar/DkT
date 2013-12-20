//
//  Created by Matthew Zorn on 10/6/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDownload.h"
#import "DkTDocketEntry.h"


@implementation DkTDownload

-(id) init
{
    if(self = [super init])
    {
        self.completionBlock = nil;
        _status = DkTDownloadCompletionStatusNone;
    }
    
    return self;
}

-(id) initWithCompletionBlock:(DkTDownloadCompletionBlock)cBlock
{
    if(self = [super init])
    {
        self.completionBlock = cBlock;
        _status = DkTDownloadCompletionStatusNone;
    }
    
    return self;
}

-(id) initWithEntry:(DkTDocketEntry *)entry completionBlock:(DkTDownloadCompletionBlock)cBlock
{
    if(self = [super init])
    {
        self.completionBlock = cBlock;
        _status = DkTDownloadCompletionStatusNone;
        self.entry = entry;
    }
    
    return self;
}


-(void) addEntries:(NSArray *)attachments completionBlock:(DkTDownloadCompletionBlock)cBlock
{
    NSMutableArray *array = [NSMutableArray array];
    for(DkTDocketEntry *entry in attachments)
    {
        DkTDownload *download = [[DkTDownload alloc] initWithEntry:entry completionBlock:cBlock];
        download.parent = self;
        [array addObject:download];
    }
    self.children = [[NSArray alloc] initWithArray:array];
    _completedChildren = 0;
}

-(void) setStatus:(DkTDownloadCompletionStatus)status
{
    if(_status != status) _status = status;
    
    if(status != DkTDownloadCompletionStatusNone)
    {
        __weak DkTDownload *weakSelf = self;
        
        if(self.completionBlock)
        {
            self.completionBlock(weakSelf, status);
            self.completionBlock = nil;
        }
    }
}

-(DkTDownloadCompletionStatus) updateCompletionStatus
{
    
    if(self.children.count == 0) return self.status;
    
    else {
        
        DkTDownloadCompletionStatus status = DkTDownloadCompletionStatusComplete;
        
        int i = 0;
        while ( (status != DkTDownloadCompletionStatusNone) && (i < self.children.count) ) {
            
            DkTDownload *download = [_children objectAtIndex:i];
            [self setStatus:download.status];
            ++i;
            
        } //run loop assuming all complete.  If one is incomplete, then the whole block is incomplete.  If one is error or partial, then the download will be error/partial.
        
        return self.status;
    }
    
}


-(DkTDownload *) downloadForEntry:(DkTDocketEntry *)entry
{
    if(self.children.count == 0) return (self.entry == entry) ? self : nil;
    
    for(DkTDownload *download in self.children)
    {
        DkTDownload *d = [download downloadForEntry:entry];
        if (d) return d;
    }
    
    return nil;
}

-(NSInteger) completedChildren
{
    if(self.children.count == 0) return -1;
    
    else return _completedChildren;
    
}

@end


//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DkTDocket.h"

typedef enum : NSUInteger {
    
    DktEntryStatusNone = (0x1 << 0),
    DktEntryStatusLocal = (0x1 << 1),
    DktEntryStatusSecondaryClient = (0x1 << 2) 
    
} DkTEntryLookupStatus;

extern NSString* const DkTURLKey;
extern NSString* const LocalURLKey;
extern NSString* const PACERCGIURLKey;
extern NSString* const PACERDOCURLKey;
extern NSString * const kWriteableProperties[];
#define SIZE_OF_WRITEABLE_PROPERTIES 7

@interface DkTDocketEntry : NSObject

@property (nonatomic, strong) NSMutableDictionary *urls;

@property (nonatomic, copy) NSString *entryNumber;
@property (nonatomic) DkTEntryLookupStatus lookupStatus;

@property (nonatomic, copy) NSString *docID; //1021132

@property (nonatomic, copy) NSString *docLink; // /doc1/1021132
@property (nonatomic, copy) NSString *docLinkParam; // 

@property (nonatomic, copy) NSString *date; // 4/5/25
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *pages;

@property (nonatomic, weak) DkTDocket *docket;


-(NSString *)courtLink;
-(NSString *)shortCourt;
-(NSString *)valueForParamKey:(NSString *)key;
-(NSString *)urlEncodedParams;
-(NSAttributedString *) renderSummary;
-(NSString *)fileName;
-(NSString *)tempFileName;
-(NSString *)linkPath;
-(NSString *)link;
-(NSString *)entryString;

@end

@interface DKTAttachment : DkTDocketEntry

@property (nonatomic, copy) NSString *attachment;

@end

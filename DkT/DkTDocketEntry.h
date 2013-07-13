//
//  RECAPDocketEntry.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const DkTURLKey;
extern NSString* const LocalURLKey;
extern NSString* const PACERCGIURLKey;
extern NSString* const PACERDOCURLKey;

@interface DkTDocketEntry : NSObject

@property (nonatomic, strong) NSMutableDictionary *urls;

@property (nonatomic) int entry;

@property (nonatomic, copy) NSString *docID; //1021132

@property (nonatomic, copy) NSString *docLink; // /doc1/1021132
@property (nonatomic, copy) NSString *docLinkParam; // 

@property (nonatomic, copy) NSString *date; // 4/5/25
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *court;

@property (nonatomic, copy) NSString *docketName;
@property (nonatomic, copy) NSString *casenum;

@property (nonatomic) BOOL lookupFlag;

-(NSString *)courtLink;
-(NSString *)shortCourt;
-(NSString *)valueForParamKey:(NSString *)key;
-(NSString *)urlEncodedParams;
-(NSAttributedString *) renderSummary;
-(NSArray *)properties;
-(NSString *)fileName;
-(NSString *)linkPath;
-(NSString *)link;

@end

//
//  RECAPDocket.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {DocketTypeNone, DocketTypeDistrict, DocketTypeBankruptcy, DocketTypeAppellate} DocketType;

extern NSString* const DocketAppellateKey;
extern NSString* const DocketDistrictKey;
extern NSString* const DocketBankruptcyKey;
extern NSString* const DocketCriminalKeys[];

@interface DkTDocket : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *encodedName;
@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSString *updated;
@property (nonatomic, copy) NSString *court;
@property (nonatomic, copy) NSString *docketID;
@property (nonatomic, copy) NSString *case_num;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *cs_caseid;


-(DocketType)type;
-(NSString *) folder;
-(NSString *) courtLink;
-(NSString *) shortCourt;
-(NSString *) pacerCode;
-(NSArray  *) properties;
-(BOOL) isMinimallyValid;

NSString* encodeToPercentEscapeString(NSString *string);
NSString* decodeFromPercentEscapeString(NSString *string);

@end

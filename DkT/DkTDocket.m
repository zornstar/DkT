//
//  RECAPDocket.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDocket.h"
#import "DkTDocumentManager.h"

NSString* const DocketAppellateKey = @"ap";
NSString* const DocketDistrictKey = @"dc";
NSString* const DocketBankruptcyKey = @"bk";

@implementation DkTDocket


-(NSString *)folder
{
    return [[DkTDocumentManager docketsFolder] stringByAppendingPathExtension:self.case_num];
}

-(DocketType) type
{
    if(self.court.length == 0) return DocketTypeNone;
    
    if([self.court rangeOfString:DocketBankruptcyKey].location != NSNotFound) return DocketTypeBankruptcy;
    
    if([self.court rangeOfString:DocketAppellateKey].location != NSNotFound) return DocketTypeAppellate;
        
    if([self.court rangeOfString:DocketDistrictKey].location != NSNotFound) return DocketTypeDistrict;
    
    return DocketTypeNone;
}
@end

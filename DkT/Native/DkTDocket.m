
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDocket.h"
#import "DkTDocumentManager.h"
#import <objc/runtime.h>

NSString* const DocketBankruptcyAppellateKey = @"bap";
NSString* const DocketAppellateKey = @"ca";
NSString* const DocketDistrictKey = @"dc";
NSString* const DocketBankruptcyKey = @"bk";
NSString* const DocketCriminalKeys[] = {
    @"cr", @"po", @"mj"
};

@implementation DkTDocket

NSString* encodeToPercentEscapeString(NSString *string) {
    return (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                              (CFStringRef) string,
                                                              NULL,
                                                              (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8));
}

NSString* decodeFromPercentEscapeString(NSString *string) {
    return (NSString *)
    CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                              (CFStringRef) string,
                                                                              CFSTR(""),
                                                                              kCFStringEncodingUTF8));
}

-(NSString *)folder
{
    return [[DkTDocumentManager docketsFolder] stringByAppendingPathExtension:self.case_num];
}

-(BOOL) isMinimallyValid
{
    return ( (self.name.length > 0) && (self.case_num.length > 0) && (self.link.length > 0));
}

-(DocketType) type
{
    if(self.court.length == 0) return DocketTypeNone;
    
    if([self.court rangeOfString:DocketBankruptcyKey].location != NSNotFound) return DocketTypeBankruptcy;
    
    if([self.court rangeOfString:DocketDistrictKey].location != NSNotFound) return DocketTypeDistrict; //important: must come before appellate otherwise california district courts will return as appellate courts
    
    if([self.court rangeOfString:DocketBankruptcyAppellateKey].location != NSNotFound) return DocketTypeAppellate;
    
    if([self.court rangeOfString:DocketAppellateKey].location != NSNotFound) return DocketTypeAppellate;
    
    /*
    else {
        for(NSString *key in [DkTDocket criminalKeys])
        {
            if([self.court rangeOfString:key].location != NSNotFound) return DocketTypeCriminal;
        }
    }*/
    
    
    return DocketTypeNone;
}

-(NSString *)courtLink
{
    return [NSString stringWithFormat:@"https://ecf.%@.uscourts.gov/",self.shortCourt];
}

-(NSString *) shortCourt
{
    NSString *str;
    
    switch (self.type) {
        case DocketTypeAppellate: {
            if([self.court rangeOfString:@"fc"].location != NSNotFound) str = @"cafc";
            else str = [NSString stringWithFormat:@"ca%d",[[self.court substringToIndex:2] intValue]];
        }
            break;
        case DocketTypeBankruptcy:
        case DocketTypeDistrict:
            str = [self.court substringToIndex:self.court.length-2];
            break;
        default:
            str = @"";
            break;
    }
    
    return str;
}

-(NSString *) pacerCode
{
    NSString *str;
    
    switch (self.type) {
        case DocketTypeAppellate: {
            if([self.court rangeOfString:@"fc"].location != NSNotFound) str = @"cafc";
            else str = [self.court substringToIndex:2];
        }
            break;
        case DocketTypeBankruptcy:
        case DocketTypeDistrict:
            str = [self.court substringToIndex:self.court.length-3];
            break;
        default:
            str = @"";
            break;
    }
    
    return str;
}

- (NSArray *) properties
{
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    NSMutableArray *array = [NSMutableArray array];
    
    unsigned i;
    for (i = 0; i < count; i++)
    {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        [array addObject:name];
    }
    
    free(properties);
    
    return array;
}

-(NSString *)encodedName
{
    return encodeToPercentEscapeString(self.name);
}

+ (NSArray *)criminalKeys
{
    static NSArray *criminalKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        criminalKeys = [NSArray arrayWithObjects:DocketCriminalKeys[0],DocketCriminalKeys[1],DocketCriminalKeys[2], nil];
    });
    
    return criminalKeys;
}

@end

//
//  RECAPDocketEntry.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDocketEntry.h"
#import "AFNetworking.h"
#import "DkTConstants.h"

#import <objc/runtime.h>

NSString* const DkTURLKey = @"archive";
NSString* const LocalURLKey = @"local";
NSString* const PACERDOCURLKey = @"pacerdoc";
NSString *const PACERCGIURLKey = @"pacercgi";

@implementation DkTDocketEntry

-(id) init
{
    if(self = [super init])
    {
        _urls = [NSMutableDictionary dictionaryWithCapacity:4];
        _lookupFlag = FALSE;
    }
    
    return self;
    
}
-(NSString *)courtLink
{
    return [NSString stringWithFormat:@"https://ecf.%@.uscourts.gov",[self shortCourt]];
}

-(NSString *)valueForParamKey:(NSString *)key
{
    NSCharacterSet *chars = [NSCharacterSet characterSetWithCharactersInString:@"KV"];
    
    NSArray *keys = [self.docLinkParam componentsSeparatedByCharactersInSet:chars];
    
    for(int i = 0; i < keys.count; i=i+2)
    {
     
        NSString *k = [keys objectAtIndex:i];
        
        if([k isEqualToString:key])
        {
            return [keys objectAtIndex:i+1];
        }
        
    }
    return nil;
    
    
}

-(NSString *)urlEncodedParams
{
    NSString *str = self.docLinkParam;
    
    str = [str stringByReplacingOccurrencesOfString:@"documentK" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"K" withString:@"&"];
    str = [str stringByReplacingOccurrencesOfString:@"V" withString:@"="];
    
    return str;
}

-(NSAttributedString *) renderSummary
{
    NSMutableAttributedString *returnStr = [[NSMutableAttributedString alloc] initWithString:@""];
    
    NSScanner *scanner = [NSScanner scannerWithString:self.summary];
    scanner.charactersToBeSkipped = NULL;
    NSString *tempText = nil;
    NSString *tagText = nil;
    
    [scanner scanUpToString:@">" intoString:nil];
    [scanner setScanLocation:[scanner scanLocation] + 1];
    
    while (![scanner isAtEnd])
    {
        [scanner scanUpToString:@"<" intoString:&tempText];
        
        
        
        if (tempText != nil)
        {
            
            NSAttributedString *tempAttrText = [[NSAttributedString alloc] initWithString:tempText attributes:@{NSForegroundColorAttributeName:kDarkTextColor}];
            [returnStr appendAttributedString:tempAttrText];
            
            if (![scanner isAtEnd])
                [scanner setScanLocation:[scanner scanLocation] + 1];
            
            if([self.summary characterAtIndex:[scanner scanLocation]] == 'a')
            {
                [scanner scanUpToString:@">" intoString:nil];
                
                [scanner setScanLocation:[scanner scanLocation] + 1];
                [scanner scanUpToString:@"</a>" intoString:&tagText];
                
                NSAttributedString *tempAttrTag = [[NSAttributedString alloc] initWithString:tagText attributes:@{NSForegroundColorAttributeName:kInactiveColor,
                                    NSBackgroundColorAttributeName:kActiveColor}];
                
                [returnStr appendAttributedString:tempAttrTag];
                
                [scanner setScanLocation:[scanner scanLocation] + 3];
            }
            
            else
            {
                [scanner scanUpToString:@">" intoString:nil];
                
            }
            
            if (![scanner isAtEnd])
                [scanner setScanLocation:[scanner scanLocation] + 1];
            
            
        }
        
    }
    
    return [[NSAttributedString alloc] initWithAttributedString:returnStr];
    
}

- (NSArray *) properties
{
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    NSMutableArray *rv = [NSMutableArray array];
    
    unsigned i;
    for (i = 0; i < count; i++)
    {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        [rv addObject:name];
    }
    
    free(properties);
    
    return rv;
}

-(NSString *)fileName
{
    NSString *caseid = [self valueForParamKey:@"caseid"];
    NSString *filename = [NSString stringWithFormat:@"%@ - %d.pdf", caseid, self.entry];
    return filename;
}

-(NSString *)shortCourt
{
    NSString *court = self.court;
    court = [court substringToIndex:court.length-2];
    return court;
}

-(NSString *)linkPath
{
    return [self.link substringFromIndex:[self courtLink].length];
}

-(NSString *)link
{
    NSString *l;
    
    if( (l = [self.urls objectForKey:PACERDOCURLKey]) )
    {
        return l;
    }
    
    else if ( (l = [self.urls objectForKey:PACERCGIURLKey]) )
    {
        return l;
    }
    
    else return nil;
}

@end

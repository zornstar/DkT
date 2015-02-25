
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDocketEntry.h"
#import "AFNetworking.h"
#import "DkTConstants.h"
#import <objc/runtime.h>


NSString * const DkTURLKey = @"archive";
NSString * const LocalURLKey = @"local";
NSString * const PACERDOCURLKey = @"pacerdoc";
NSString * const PACERCGIURLKey = @"pacercgi";
NSString * const kWriteableProperties[] = {
    @"urls",@"entryNumber", @"lookupStatus", @"docID", @"docLinkParam",@"date",@"summary"
};

@implementation DkTDocketEntry

-(id) init
{
    if(self = [super init])
    {
        _urls = [NSMutableDictionary dictionaryWithCapacity:4];
        _lookupStatus = DktEntryStatusNone;
        _entryNumber = @"0";
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
    
    NSString *string = [self.summary stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    string = [string stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    string = [string stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = NULL;
    NSString *tempText = nil;
    NSString *tagText = nil;
    if([self.summary characterAtIndex:0] == '<')
    {
        [scanner scanUpToString:@">" intoString:nil];
        [scanner setScanLocation:[scanner scanLocation] + 1];
    }
    
    while (![scanner isAtEnd])
    {
        [scanner scanUpToString:@"<" intoString:&tempText];
        
        if (tempText != nil)
        {
            
            NSAttributedString *tempAttrText = [[NSAttributedString alloc] initWithString:tempText attributes:@{NSForegroundColorAttributeName:[UIColor darkerTextColor]}];
            [returnStr appendAttributedString:tempAttrText];
            
            if ([scanner isAtEnd]) break;
            
            [scanner setScanLocation:[scanner scanLocation] + 1];
            if(([self.summary characterAtIndex:scanner.scanLocation-1] == '<') && ([self.summary characterAtIndex:[scanner scanLocation]] == 'a'))
            {
                [scanner scanUpToString:@">" intoString:nil];
                [scanner setScanLocation:[scanner scanLocation] + 1];
                [scanner scanUpToString:@"</a>" intoString:&tagText];
                
                NSAttributedString *tempAttrTag = [[NSAttributedString alloc] initWithString:tagText attributes:@{NSForegroundColorAttributeName:[UIColor activeColor]}];
                
                [returnStr appendAttributedString:tempAttrTag];
                
                [scanner setScanLocation:[scanner scanLocation] + 3];
            }

            else
            {
                [scanner scanUpToString:@">" intoString:nil];
                
            }
            
            
            [scanner setScanLocation:[scanner scanLocation] + 1];
            
        }
        
        else
        {
            [scanner scanUpToString:@">" intoString:nil];
            [scanner setScanLocation:[scanner scanLocation] + 1];
        }
        
    }
    
    if(self.pages.length > 0)
    {
        NSString *append = [NSString stringWithFormat:@" (%@)", self.pages];
        [returnStr appendAttributedString:[[NSAttributedString alloc] initWithString:append]];
    }
    
    NSAttributedString *returnString = [[NSAttributedString alloc] initWithAttributedString:returnStr];
    return returnString;
    
}

/*
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
}*/

-(NSString *)fileName
{
    NSString *filename = [NSString stringWithFormat:@"Entry #%@.pdf", self.entryString];
    return filename;
}

-(NSString *)tempFileName {
    NSString *uid = @"";
    
    if(self.docket.name.length > 0) {
        uid = [[uid stringByAppendingString:[self.docket.name substringToIndex:1]] stringByAppendingString:@"&"];
    }
    
    if(self.docket.cs_caseid.length > 2) {
        uid = [[uid stringByAppendingString:[self.docket.cs_caseid substringToIndex:3]] stringByAppendingString:@"&"];
    }
    
    if(self.docket.court) {
        uid = [uid stringByAppendingString:self.docket.court];
        uid = [uid stringByAppendingString:@"&"];
    }
    
    return [uid stringByAppendingString:self.fileName];
}

-(NSString *)shortCourt
{
    NSString *court = self.docket.court;
    court = [court substringToIndex:court.length-2];
    return court;
}

-(NSString *)linkPath
{
    NSString *linkPath = [self.link substringFromIndex:[self courtLink].length];
    return linkPath;
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

-(NSString *)entryString
{
    return self.entryNumber;
}

-(NSString *)docID
{
    return [[[self.urls objectForKey:PACERDOCURLKey] componentsSeparatedByString:@"/"] lastObject];
}
@end

@implementation DKTAttachment

-(NSString *)entryString
{
    return [NSString stringWithFormat:@"%@.%@",self.entryNumber, self.attachment];
}

-(NSString *)fileName
{
    return [NSString stringWithFormat:@"Entry #%@-%@.pdf", self.entryNumber, self.attachment];
}
@end
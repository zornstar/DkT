//
//  PACERParser.m
//  DkTp
//
//  Created by Matthew Zorn on 5/28/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "PACERParser.h"
#import "DkTDocketEntry.h"
#import "DkTDocket.h"
#import "TFHpple.h"
#import "GDataXMLNode.h"

@implementation PACERParser

+(NSString *)parseDocketSheet:(NSData *)html courtType:(PACERCourtType)type
{
    if(type == PACERCourtTypeCivil)
    {
        TFHpple *hpple = [TFHpple hppleWithHTMLData:html];
        TFHppleElement *firstForm = [hpple peekAtSearchWithXPathQuery:@"//form"];
        NSString *fullDocketReport = [firstForm objectForKey:@"action"];
        NSRange rangeOfQMark = [fullDocketReport rangeOfString:@"?"];
        NSString *fullDocketReportGetURLString = [fullDocketReport substringFromIndex:rangeOfQMark.location];
        return fullDocketReportGetURLString;
    }
    
    else return nil;
}

+(BOOL) parseLogin:(NSData *)html
{
    NSString *stringData = [[NSString alloc] initWithData:html encoding:NSUTF8StringEncoding];
    
    if ([stringData rangeOfString:@"Login Error"].location != NSNotFound) {
        return FALSE;
    }
    
    TFHpple *hpple = [TFHpple hppleWithHTMLData:html];
    
    NSArray *inputElements = [hpple searchWithXPathQuery:@"//input"];
    
    for(TFHppleElement *element in inputElements)
    {
        if([[element objectForKey:@"id"] isEqualToString:@"loginid"]) return FALSE;
        if([[element objectForKey:@"name"] isEqualToString:@"login"]) return FALSE;
    }
    
    return TRUE;
}

+(BOOL) isLoggedIn:(NSData *)html
{
    return [PACERParser parseLogin:html];
}

+(NSMutableArray *) parseSearchResults:(NSData *)html
//:(NSData *)data recursively:(BOOL)dive
{
    
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:html];
    TFHppleElement *details = [hpple peekAtSearchWithXPathQuery:@"//div[@id='details']"];
    NSMutableArray *returnArray = [NSMutableArray array];
    NSArray *tables = [details childrenWithTagName:@"table"];
    
    for(TFHppleElement *table in tables)
    {
        NSArray *rows;
        
        if(tables.count > 1)
        {
            TFHppleElement *tbody = [[table childrenWithTagName:@"tbody"] objectAtIndex:0];
            rows = [tbody childrenWithTagName:@"tr"];
        }
        
        else rows = [table childrenWithTagName:@"tr"];
            
        TFHppleElement *firstRow = [rows objectAtIndex:0];
        NSString *title = [firstRow firstChild].text;
            
        NSMutableArray *itemsArray = [NSMutableArray array];
            
        for(int r = 1; r < rows.count; ++r) {
            
            DkTDocket *result = [[DkTDocket alloc] init];
            TFHppleElement *e = [rows objectAtIndex:r];
            NSString *str;
            NSArray *children = [e children];
                
            for(int i = 0; i < children.count; ++i) {
                    
                TFHppleElement *child = [children objectAtIndex:i];
                    
                str = [child objectForKey:@"class"];
                    
                if([str isEqualToString:@"cs_title"]) result.name = child.text;
                    
                if([str isEqualToString:@"cs_date"]) if(result.date.length < 1) result.date = child.text; //We want the date filed only, which is the first date.
                    
                if([str isEqualToString:@"court_id"]) result.court = child.text;
                    
                if([str isEqualToString:@"case"]) {
                        
                    TFHppleElement *aChild = [[child childrenWithTagName:@"a"] objectAtIndex:0];
                    result.link = [aChild objectForKey:@"href"];
                    result.case_num = aChild.text;
                }
            }
            [itemsArray addObject:result];
        }
            
            NSDictionary *tableDict = @{@"name":title, @"items":itemsArray};
            [returnArray addObject:tableDict];
    }
    
    return returnArray;
}
    


+(NSArray *)parseAppellateDocket:(DkTDocket *)docket xml:(NSData *)xml
{
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xml options:0 error:nil];
    
    GDataXMLElement *docketTextsElement = [[doc.rootElement elementsForName:@"docketTexts"] objectAtIndex:0];
    
    NSMutableArray *returnArray = [NSMutableArray array];
    
    for(GDataXMLElement *e in [docketTextsElement children])
    {
        DkTDocketEntry *entry = [[DkTDocketEntry alloc] init];
        
        entry.summary = [PACERParser stripBracketedFromString:[e attributeForName:@"text"].stringValue];
        entry.date = [e attributeForName:@"dateFiled"].stringValue;
        NSString *link = [e attributeForName:@"docLink"].stringValue;
        [entry.urls setObject:link forKey:PACERDOCURLKey];
        entry.summary = [e attributeForName:@"text"].stringValue;
        
        //copy from docket
        entry.casenum = [docket.case_num copy];
        entry.docketName = [docket.name copy];
        
        [returnArray addObject:entry];
    }
    
    return [NSArray arrayWithArray:returnArray];
    
}

+(NSArray *) parseDocket:(DkTDocket *)docket html:(NSData *)data
{
    
    if(docket.type == DocketTypeBankruptcy) return [PACERParser parseBankruptcyDocket:docket html:data];
    
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    NSArray *tables = [hpple searchWithXPathQuery:@"//table"];
    
    TFHppleElement *table;
    
    for(TFHppleElement *t in tables)
    {
        if([[t objectForKey:@"rules"] isEqualToString:@"all"])
        {
            table = t;
            break;
        }
    }
    
    NSArray *docket_rows = [table childrenWithTagName:@"tr"];
    
    NSMutableArray *returnArray = [NSMutableArray array];
    
    for(int i = 1; i < docket_rows.count; ++i)
    {
        TFHppleElement *current_docket_row = [docket_rows objectAtIndex:i];
        NSArray *docket_cols = [current_docket_row childrenWithTagName:@"td"];
        
        //Create the docket entry
        DkTDocketEntry *entry = [[DkTDocketEntry alloc] init];
        
        entry.court = [docket.court copy];
        
        int col_num = 0;
        
        //Column 1 = date
        entry.date = ((TFHppleElement *)[docket_cols objectAtIndex:col_num]).text;
        
        col_num++; //bankruptcy has 4 columns
        
        //Column 2 = link
        TFHppleElement *link_col = [docket_cols objectAtIndex:col_num];
        
        NSArray *links = [link_col childrenWithTagName:@"a"];
        
        if(links.count > 0)
        {
            
            TFHppleElement *link_entry = [links objectAtIndex:0];
            
            NSString *link = [link_entry objectForKey:@"href"];
            
            if(link)
            {
                if([link hasPrefix:@"/"])
                {
                    link = [[entry courtLink] stringByAppendingPathComponent:link];
                }
                
                if([link rangeOfString:@"doc1"].location != NSNotFound)
                {
                    [entry.urls setObject:[link copy] forKey:PACERDOCURLKey];
                }
                
                else if ([link rangeOfString:@"cgi"].location != NSNotFound)
                {
                    
                    [entry.urls setObject:[link copy] forKey:PACERCGIURLKey];
                }
                
                
            }
            
            
            
            entry.entry = [[link_entry text] integerValue];
            entry.docLinkParam = [link_entry objectForKey:@"id"];
            
        }
        
        
        
        ++col_num;
        
        //Column 3 = contents
        TFHppleElement *contents_col = [docket_cols objectAtIndex:col_num];
        entry.summary = contents_col.raw;
        
        //copy from docket
        entry.casenum = [docket.case_num copy];
        entry.docketName = [docket.name copy];
        
        
        
        
        //search for the word attachment
        // NSRange attachment_range = [contents_col.content rangeOfString:@"Attachments:"];
        
        /*
         if(attachment_range.location != NSNotFound)
         {
         NSString *attachment_text = [contents_col.content substringFromIndex:attachment_range.location];
         entry.exhibits = [self parseAttachmentText:attachment_text];
         }
         */
        [returnArray addObject:entry];
    }
    
    return (NSArray *)returnArray;
}

+(NSArray *) parseBankruptcyDocket:(DkTDocket *)docket html:(NSData *)data
{
    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    NSArray *tables = [hpple searchWithXPathQuery:@"//table"];
    TFHppleElement *table = [tables lastObject];
    
    NSArray *docket_rows = [table childrenWithTagName:@"tr"];
    
    NSMutableArray *returnArray = [NSMutableArray array];
    
    for(int i = 1; i < docket_rows.count; ++i)
    {
        TFHppleElement *current_docket_row = [docket_rows objectAtIndex:i];
        NSArray *docket_cols = [current_docket_row childrenWithTagName:@"td"];
        
        //Create the docket entry
        DkTDocketEntry *entry = [[DkTDocketEntry alloc] init];
        
        entry.court = [docket.court copy];
        
        int col_num = 0;
        
        //Column 1 = date
        entry.date = ((TFHppleElement *)[docket_cols objectAtIndex:col_num]).text;
        
        col_num = 2; //bankruptcy has 4 columns
        
        //Column 2 = link
        TFHppleElement *link_col = [docket_cols objectAtIndex:col_num];
        
        NSArray *links = [link_col childrenWithTagName:@"a"];
        
        if(links.count > 0)
        {
            
            TFHppleElement *link_entry = [links objectAtIndex:0];
            
            NSString *link = [link_entry objectForKey:@"href"];
            
            if(link)
            {
                if([link hasPrefix:@"/"])
                {
                    link = [[entry courtLink] stringByAppendingPathComponent:link];
                }
                
                if([link rangeOfString:@"doc1"].location != NSNotFound)
                {
                    [entry.urls setObject:[link copy] forKey:PACERDOCURLKey];
                }
                
                else if ([link rangeOfString:@"cgi"].location != NSNotFound)
                {
                    
                    [entry.urls setObject:[link copy] forKey:PACERCGIURLKey];
                }
                
                
            }
            
            entry.entry = [[link_entry text] integerValue];
            
        }
        
        
        
        ++col_num;
        
        //Column 3 = contents
        TFHppleElement *contents_col = [docket_cols objectAtIndex:col_num];
        entry.summary = contents_col.raw;
        
        //copy from docket
        entry.casenum = [docket.case_num copy];
        entry.docketName = [docket.name copy];
        
        [returnArray addObject:entry];
    }

    return returnArray;
}

+(NSString *)parseForNextPage:(NSData *)html
{
    TFHpple *hpple = [TFHpple hppleWithData:html isXML:NO];
    
    TFHppleElement *pageSelectElement = [hpple peekAtSearchWithXPathQuery:@"//div[@id='page_select0']"];
    
    if(pageSelectElement != nil)
    {
        NSArray *children = [pageSelectElement children];
        
        if(children.count > 1)
        {
            TFHppleElement *nextPageElement = [children lastObject];
            return [nextPageElement objectForKey:@"href"];
        }
    }
    
    return nil;
}

+(float) parseAppellateCost:(NSData *)html
{
    TFHpple *hpple = [TFHpple hppleWithData:html isXML:NO];
    
    TFHppleElement *costTable = [hpple peekAtSearchWithXPathQuery:@"//TABLE[@WIDTH='400']"];
    
    NSArray *children = [costTable children];
    
    TFHppleElement *lastRow = [children lastObject];
    
    TFHppleElement *lastColumn = [[lastRow childrenWithTagName:@"TD"] lastObject];
    
    TFHppleElement *font = [[lastColumn childrenWithTagName:@"FONT"] lastObject];
    
    return [font.text floatValue];
    
}

+(float) parsePACERCost:(NSData *)html
{
    TFHpple *hpple = [TFHpple hppleWithData:html isXML:NO];
    
    TFHppleElement *costTable = [hpple peekAtSearchWithXPathQuery:@"//TABLE[@WIDTH='receipt']"];
    
    TFHppleElement *tbody = [[costTable childrenWithTagName:@"tbody"] objectAtIndex:0];
    
    NSArray *children = [tbody children];
    
    TFHppleElement *lastRow = [children lastObject];
    
    TFHppleElement *lastColumn = [[lastRow childrenWithTagName:@"TD"] lastObject];
    
    NSString *costString = lastColumn.text;
    NSRange startRange = [costString rangeOfString:@"($"];
    NSRange endRange = [costString rangeOfString:@")"];
    NSString *cost = [costString substringWithRange:NSMakeRange(startRange.location+2, endRange.location-(startRange.location+2))];
    return [cost floatValue];
    
}

+(NSString *)stripLinkFromString:(NSString *)str {
    NSRange range;
    NSString *returnString = [str copy];
    
    while ((range = [str rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
    {
        [returnString stringByReplacingCharactersInRange:range withString:@""];
    };
    
    return returnString;
}

+(NSString *)stripBracketedFromString:(NSString *)str
{
    NSRange range;
    NSString *returnString = [str copy];
    
    while ((range = [str rangeOfString:@"[[^>]+]" options:NSRegularExpressionSearch]).location != NSNotFound)
    {
        [returnString stringByReplacingCharactersInRange:range withString:@""];
    };
    
    return returnString;
}

+(NSArray *)parseDocumentPage:(NSData *)html
{
    NSMutableArray *returnArray = [NSMutableArray array];
    TFHpple *hpple = [TFHpple hppleWithHTMLData:html];
    TFHppleElement *costTable = [hpple peekAtSearchWithXPathQuery:@"//table"];
    TFHppleElement *tbody = [costTable firstChild];
    NSArray *rows = [tbody children];
    
    TFHppleElement *firstRow = [rows objectAtIndex:0];
    
    NSString *fullLink = [[[firstRow firstChild] firstChildWithTagName:@"a"] objectForKey:@"href"];
    DkTDocketEntry *entry = [[DkTDocketEntry alloc] init];
    entry.name = @"Document";
    //entry.link = fullLink;
    
    for(int i = 1; i < rows.count; ++i)
    {
        TFHppleElement *row = [rows objectAtIndex:i];
        NSArray *columns = [row children];
        
        TFHppleElement *firstColumn = [columns objectAtIndex:0];
            
        if([firstColumn firstChildWithTagName:@"a"])
        {
            DkTDocketEntry *newEntry = [[DkTDocketEntry alloc] init];
           // newEntry.link = [[firstColumn firstChildWithTagName:@"a"] objectForKey:@"href"];
            newEntry.name = [((TFHppleElement *)[columns objectAtIndex:1]) text] ;
            [returnArray addObject:entry];
        }
        
        if(i == rows.count - 1)
        {
            NSString *clickLink = [[firstColumn firstTextChild] objectForKey:@"onclick"];
            NSArray *components = [clickLink componentsSeparatedByString:@"'"];
            DkTDocketEntry *newEntry = [[DkTDocketEntry alloc] init];
           // newEntry.link = [components objectAtIndex:components.count-2];
            newEntry.name = @"All";
            [returnArray addObject:entry];
        }
    }
    
    return returnArray;

}

+(float) parseHtmlStringForCost:(NSString *)htmlString
{
    NSRange range = [htmlString rangeOfString:@"($"];
    
    float cost = 0;
    
    if(range.location != NSNotFound)
    {
        NSRange endRange = [htmlString rangeOfString:@")" options:NSCaseInsensitiveSearch range:NSMakeRange(range.location, range.location-htmlString.length-1)];
        
        if(endRange.location != NSNotFound)
        {
            NSString *costString = [htmlString substringWithRange:NSMakeRange(range.location, endRange.location - range.location)];
            cost = [costString floatValue];
        }
    }
    
    return cost;
}

+(NSString *) pdfURLForDownloadDocument:(NSData *)data
{
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    TFHppleElement *pdf = [[hpple searchWithXPathQuery:@"//a"] lastObject];
    
    if(pdf) return [pdf objectForKey:@"href"];
    
    else return nil;
}

@end

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

+(NSArray *)parseAppellateMultiDoc:(DkTDocketEntry *)entry html:(NSData *)html
{
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:html];
    NSMutableArray *entries = [NSMutableArray array];
    
    NSArray *tables = [hpple searchWithXPathQuery:@"//table"];
    TFHppleElement *table = [tables lastObject];
    
    NSArray *rows = [table childrenWithTagName:@"tr"];
    
    for(int i = 1; i < rows.count; ++i)
    {
            
            DKTAttachment *e = [[DKTAttachment alloc] init];
            TFHppleElement *row = [rows objectAtIndex:i];
            
            NSArray *tds = [row childrenWithTagName:@"td"];
            
            e.entryNumber = entry.entryNumber;
            e.attachment = ((TFHppleElement *)[tds objectAtIndex:0]).text;
            
            TFHppleElement *linkElement = [tds objectAtIndex:1];
            NSString *link = [[linkElement firstChildWithTagName:@"a"] objectForKey:@"href"];
            
            if([link rangeOfString:@"docs1"].location != NSNotFound)
            {
                [e.urls setObject:[link copy] forKey:PACERDOCURLKey];
            }
            
            e.summary = [[tds objectAtIndex:2] text];
            e.docket = entry.docket;
        
        [entries addObject:e];
        
    }
    
    return entries;
}

+(NSArray *)parseMultiDoc:(DkTDocketEntry *)entry html:(NSData *)html
{
    NSMutableArray *entries = [NSMutableArray array];
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:html];
    
    TFHppleElement *table = [hpple peekAtSearchWithXPathQuery:@"//table"];
   
    NSArray *rows;
    
    NSArray *tbody = [table childrenWithTagName:@"tbody"];
    
    if(tbody.count > 0) rows = [[tbody objectAtIndex:0] childrenWithTagName:@"tr"];
    
    else rows = [table childrenWithTagName:@"tr"];
    
    TFHppleElement *firstRowElement = [rows objectAtIndex:0];
    
    DKTAttachment *firstEntry = [[DKTAttachment alloc] init];
    firstEntry.summary = [entry summary];
    firstEntry.docket = entry.docket;
    NSArray *tdArray = [firstRowElement childrenWithTagName:@"td"];
    if(tdArray.count == 0)
    {
        firstRowElement = [rows objectAtIndex:1];
        tdArray = [firstRowElement childrenWithTagName:@"td"];
    }
    
    TFHppleElement *linkElement =  [[tdArray objectAtIndex:0] firstChildWithTagName:@"a"];
    firstEntry.entryNumber = linkElement.text;
    firstEntry.attachment = @"0";
    NSString *link = [linkElement objectForKey:@"href"];
    
    
    
    if(link)
    {
        if([link hasPrefix:@"/"])
        {
            link = [[firstEntry courtLink] stringByAppendingPathComponent:link];
        }
        
        if([link rangeOfString:@"doc1"].location != NSNotFound)
        {
            [firstEntry.urls setObject:[link copy] forKey:PACERDOCURLKey];
        }
        
        else if ([link rangeOfString:@"cgi"].location != NSNotFound)
        {
            
            [firstEntry.urls setObject:[link copy] forKey:PACERCGIURLKey];
        }
    }
    
    firstEntry.pages = [[tdArray objectAtIndex:1] text];
    
    [entries addObject:firstEntry];
    
    for(int i = 3; i < rows.count-2; i++)
    {
        TFHppleElement *tr = [rows objectAtIndex:i];
        NSArray *tds = [tr childrenWithTagName:@"td"];
        DKTAttachment *attachment = [[DKTAttachment alloc] init];
        
        TFHppleElement *linkElement =  [[tds objectAtIndex:0] firstChildWithTagName:@"a"];
        attachment.entryNumber = firstEntry.entryNumber;
        attachment.attachment = linkElement.text;
        attachment.docket = entry.docket;
        
        NSString *link = [linkElement objectForKey:@"href"];
        
        if(link)
        {
            if([link hasPrefix:@"/"])
            {
                link = [[firstEntry courtLink] stringByAppendingPathComponent:link];
            }
            
            if([link rangeOfString:@"doc1"].location != NSNotFound)
            {
                [attachment.urls setObject:[link copy] forKey:PACERDOCURLKey];
            }
            
            else if ([link rangeOfString:@"cgi"].location != NSNotFound)
            {
                
                [attachment.urls setObject:[link copy] forKey:PACERCGIURLKey];
            }
        }
        
        attachment.summary =  [(TFHppleElement *)[tds objectAtIndex:1] raw];
        attachment.pages =  [[tds objectAtIndex:2] text];
        attachment.docket = entry.docket;
        [entries addObject:attachment];
        
    }
    
    return entries;
    
}

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
{

    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:html];
    TFHppleElement *details = [hpple peekAtSearchWithXPathQuery:@"//div[@id='details']"];
    NSMutableArray *returnArray = [NSMutableArray array];
    NSArray *_tables = [details childrenWithTagName:@"table"];
    NSMutableArray *tables = [NSMutableArray array];
    for(TFHppleElement *table in _tables)
    {
        [tables addObject:table];
        
        NSArray *chtables = [table childrenWithTagName:@"table"];
        
        while (chtables.count > 0) {
            
            for(TFHppleElement *chtable in chtables)
            {
                if([[chtable objectForKey:@"align"] isEqualToString:@"center"])
                {
                    [tables addObject:chtable];
                    chtables = [chtable childrenWithTagName:@"table"];
                    break;
                }
                
            }
        }
        
    }
    for(TFHppleElement *table in tables) {
    
        NSArray *rows;
        
        if(tables.count > 1)
        {
            NSArray *tbodies = [table childrenWithTagName:@"tbody"];
            
            if(tbodies.count == 0) rows = [table childrenWithTagName:@"tr"];
            
            else {
                
                
                TFHppleElement *tbody = [tbodies objectAtIndex:0];
                
                rows = [tbody childrenWithTagName:@"tr"];
            }
        }
    
        else rows = [table childrenWithTagName:@"tr"];
            
        TFHppleElement *firstRow = [rows objectAtIndex:0];
        NSString *title = [firstRow firstChild].text;
            
        NSMutableArray *itemsArray = [NSMutableArray array];
            
        for(int r = 1; r < rows.count; ++r) {
            
            @autoreleasepool {
                
                DkTDocket *result = [[DkTDocket alloc] init];
                TFHppleElement *e = [rows objectAtIndex:r];
                
                NSArray *children = [e childrenWithTagName:@"td"];
                
                for(int i = 0; i < children.count; ++i) {
                    
                    @autoreleasepool {
                        
                        TFHppleElement *child = [children objectAtIndex:i];
                        
                        NSString *str = [child objectForKey:@"class"];
                        
                        if([str isEqualToString:@"cs_date"]) if(result.date.length < 1) result.date = child.text; //We want the date filed only, which is the first date.
                        
                        if([str isEqualToString:@"court_id"]) result.court = child.text;
                        
                        if([str isEqualToString:@"case"]) {
                            
                            TFHppleElement *aChild = [[child childrenWithTagName:@"a"] objectAtIndex:0];
                            result.link = [aChild objectForKey:@"href"];
                            result.case_num = aChild.text;
                            result.name = [aChild objectForKey:@"title"];
                            
                        }
                        
                        TFHppleElement *td1 = [children objectAtIndex:2];
                        NSArray *children = [td1 childrenWithTagName:@"a"];
                        
                        if(children.count > 0)
                        {
                            TFHppleElement *caseidelement = [children objectAtIndex:0];
                            result.cs_caseid = [[[caseidelement objectForKey:@"href"] componentsSeparatedByString:@"="] lastObject];
                        }
                        
                        else if ([result.link rangeOfString:@"iquery"].location !=NSNotFound)
                        {
                            NSArray *components = [result.link componentsSeparatedByString:@"?"];
                            
                            if(components.count > 1)
                            {
                                result.cs_caseid = [components lastObject];
                            }
                        }
                        
                    }
                    
                    
                }
                
                [self cleanName:result];
                if([result isMinimallyValid])[itemsArray addObject:result];
                
            }
            
        }
        
        
        
            NSDictionary *tableDict = @{@"name":title, @"items":itemsArray};
            [returnArray addObject:tableDict];
    }
    
    return returnArray;
}

+(void) cleanName:(DkTDocket *)docket
{
    NSString *name = docket.name;
    NSRange r;
    
    while ((r = [name rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        name = [name stringByReplacingCharactersInRange:r withString:@""];
    
    r = [docket.name rangeOfString:@"DO NOT FILE IN THIS CASE"];
    
    if(r.location != NSNotFound)
    {
        name = [docket.name substringToIndex:r.location];
    }
    
    docket.name = name;
}

+(NSArray *)parseAppellateDocket:(DkTDocket *)docket html:(NSData *)html
{
    @try {
    
        TFHpple *hpple = [TFHpple hppleWithData:html isXML:NO];
        NSLog(@"%@",[[NSString alloc] initWithData:html encoding:NSUTF8StringEncoding]);
        TFHppleElement *dktEntry = [hpple peekAtSearchWithXPathQuery:@"//form[@name='dktEntry']"];
        TFHppleElement *table = [[[[dktEntry firstChildWithTagName:@"table"] firstChildWithTagName:@"tr"] firstChildWithTagName:@"td"]firstChildWithTagName:@"table"] ;
        
        NSMutableArray *returnArray = [NSMutableArray array];
        
        NSArray *rows = [table childrenWithTagName:@"tr"];
        for(TFHppleElement *row in rows)
        {
            @autoreleasepool {
                
                DkTDocketEntry *entry = [[DkTDocketEntry alloc] init];
                
                NSArray *cols = [row childrenWithTagName:@"td"];
                
                
                entry.date = ((TFHppleElement *)[cols objectAtIndex:0]).text;
                
                TFHppleElement *col2 = [cols objectAtIndex:1];
                
                TFHppleElement *linkElement = [col2 firstChildWithTagName:@"a"];
                
                
                NSString *link = [linkElement objectForKey:@"href"];
                
                if(link.length > 0) [entry.urls setObject:link forKey:PACERDOCURLKey];
                
                NSString *num;
                
                if(linkElement == nil)
                {
                    NSString *raw = col2.raw;
                    raw = [raw substringFromIndex:[raw rangeOfString:@"/>"].location+2];
                    raw = [raw substringToIndex:[raw rangeOfString:@"<"].location];
                }
                
                else
                {
                    num = (linkElement.text.length > 0) ? [NSString stringWithFormat:@"%@",linkElement.text] : [NSString stringWithFormat:@"%@",[link lastPathComponent]];
                }
                
                
                entry.entryNumber = [num stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                entry.summary = ((TFHppleElement *)[cols objectAtIndex:2]).raw;//[PACERParser stripBracketedFromString:[e attributeForName:@"text"].stringValue];
                
                entry.docket = docket;
                [returnArray addObject:entry];
                
            }
            
            
        }
        
        return [NSArray arrayWithArray:returnArray];
    }
    @catch (NSException *exception) {
        return nil;
    }
    @finally {
        
    }
    
    
}

+(NSArray *) parseDocket:(DkTDocket *)docket html:(NSData *)data
{
    @try {
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
            
            @autoreleasepool {
                
                TFHppleElement *current_docket_row = [docket_rows objectAtIndex:i];
                NSArray *docket_cols = [current_docket_row childrenWithTagName:@"td"];
                
                //Create the docket entry
                DkTDocketEntry *entry = [[DkTDocketEntry alloc] init];
                
                entry.docket = docket;
                
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
                    
                    
                    if([[link_entry text] length] > 0) entry.entryNumber = [link_entry text];
                    
                    entry.docLinkParam = [link_entry objectForKey:@"id"];
                    
                }
                
                
                
                ++col_num;
                
                //Column 3 = contents
                TFHppleElement *contents_col = [docket_cols objectAtIndex:col_num];
                entry.summary = contents_col.raw;
                
                //copy from docket
                entry.docket = docket;
                
                
                
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
            
        }
        
        return [NSArray arrayWithArray:returnArray];
    }
    @catch (NSException *exception) {
        return nil;
    }
    @finally {
        
    }
    
}

+(NSArray *) parseBankruptcyDocket:(DkTDocket *)docket html:(NSData *)data
{
    @try {
        TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
        NSArray *divs = [hpple searchWithXPathQuery:@"//div[@id='cmecfMainContent']"];
        TFHppleElement *div = [divs lastObject];
        NSArray *tables = [div childrenWithTagName:@"table"];
        TFHppleElement *table = [tables lastObject];
        TFHppleElement *tbody = [table firstChildWithTagName:@"tbody"];
        NSArray *docket_rows = (tbody == nil) ? [table childrenWithTagName:@"tr"] : [tbody childrenWithTagName:@"tr"];
        NSMutableArray *returnArray = [NSMutableArray array];
        
        for(int i = 1; i < docket_rows.count; ++i)
        {
            
            @autoreleasepool {
                
                TFHppleElement *current_docket_row = [docket_rows objectAtIndex:i];
                NSArray *docket_cols = [current_docket_row childrenWithTagName:@"td"];
                
                //Create the docket entry
                DkTDocketEntry *entry = [[DkTDocketEntry alloc] init];
                
                entry.docket = docket;
                
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
                    
                    entry.entryNumber = [link_entry text];
                    
                }
                
                
                
                ++col_num;
                
                //Column 3 = contents
                TFHppleElement *contents_col = [docket_cols objectAtIndex:col_num];
                entry.summary = contents_col.raw;
                
                //copy from docket
                entry.docket = docket;
                
                [returnArray addObject:entry];
                
            }
            
        }
        
        return returnArray;
    }
    @catch (NSException *exception) {
        return nil;
    }
    @finally {
        
    }
   
    
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
    
    while ((range = [returnString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
    {
        returnString = [returnString stringByReplacingCharactersInRange:range withString:@""];
    };
    
    return returnString;
}

+(NSString *)stripBracketedFromString:(NSString *)str
{
    NSRange range;
    NSString *returnString = [str copy];
    
    //fix
    while ((range = [returnString rangeOfString:@"\\[([^]]+)\\]" options:NSRegularExpressionSearch]).location != NSNotFound)
    {
        returnString = [returnString stringByReplacingCharactersInRange:range withString:@""];
    };
    
    return returnString;
}

+(NSString *) pdfURLForDownloadDocument:(NSData *)data
{
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    TFHppleElement *pdf = [[hpple searchWithXPathQuery:@"//a"] lastObject];
    
    if(pdf) return [pdf objectForKey:@"href"];
    
    else return nil;
}

+(void) parseAppellateCaseSelectionPage:(NSData *)html withDocket:(DkTDocket *)docket completion:(void (^)(NSString *cs_caseid))completion
{
    TFHpple *hpple = [TFHpple hppleWithData:html isXML:NO];
    NSLog(@"%@", [hpple description]);
    
    NSArray *tables = [hpple searchWithXPathQuery:@"//table"];
    
    TFHppleElement *table;
    
    for(TFHppleElement *t in tables)
    {
        if([[t objectForKey:@"border"] isEqualToString:@"1"])
        {
            table = t;
            break;
        }
    }
    
    
    if(table)
    {
        NSLog(@"%@", [table description]);
        NSArray *rows = [table childrenWithTagName:@"tr"];
        
        for(int i = 1; i < rows.count; ++i)
        {
            TFHppleElement *row = [rows objectAtIndex:i];
            
            NSArray *tds = [row childrenWithTagName:@"td"];
            
            NSString *dateString;
            
            if(tds.count > 1)
            {
                dateString = [((TFHppleElement *)[tds objectAtIndex:1]) text];
                dateString = [dateString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            
            if([dateString isEqualToString:docket.date])
            {
                TFHppleElement *td1 = [row firstChildWithTagName:@"td"];
                TFHppleElement *link = [[td1 childrenWithTagName:@"a"] lastObject];
                NSString *linkText = [link objectForKey:@"href"];
                NSArray *components = [linkText componentsSeparatedByString:@"&"];
                
                for(NSString *component in components)
                {
                    if([component rangeOfString:@"caseid"].location != NSNotFound)
                    {
                        [docket setCs_caseid:[[component componentsSeparatedByString:@"="] lastObject]];
                        break;
                    }
                }
            }
        }

    }
    completion(docket.cs_caseid);
    
    
}

@end

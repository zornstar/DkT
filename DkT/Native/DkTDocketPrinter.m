//
//  DkTDocketPrinter.m
//  DkT
//
//  Created by Matthew Zorn on 3/23/14.
//  Copyright (c) 2014 Matthew Zorn. All rights reserved.
//

#import "DkTDocketPrinter.h"
#import "DkTDocketEntry.h"
#import "DkTDocumentManager.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

@implementation DkTDocketPrinter


void DrawDocket(NSString *name, NSArray *entries, NSString *destPath)
{
    CFURLRef pdfURLOutput =(__bridge_retained CFURLRef) [[NSURL alloc] initFileURLWithPath:(NSString *)destPath];
    CGContextRef context = CGPDFContextCreateWithURL(pdfURLOutput, NULL, NULL);
    //setup some initial style references
    CTTextAlignment center = kCTTextAlignmentCenter;
    CTParagraphStyleSetting centersettings[] = { {kCTParagraphStyleSpecifierAlignment, sizeof(center),&center} };
    CTParagraphStyleRef pstylecenter = CTParagraphStyleCreate(centersettings, sizeof(centersettings)/sizeof(centersettings[0]));
    
    NSString *toc = name; CFStringRef tocRef = (__bridge CFStringRef)toc;
    CGFloat tocFontSize = 24;
    CGRect tocFrame = CGRectMake(0, 680, 612, 72);
    CGSize s = [name boundingRectWithSize:tocFrame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont fontWithName:kMainFont size:tocFontSize]} context:nil].size;
    
    if( s.height <= tocFrame.size.height)
            tocFontSize = 20;
        
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)(kMainFont), tocFontSize, NULL);
    CTFontRef stfont = CTFontCreateWithName((__bridge CFStringRef)(kContrastFont), 14, NULL);
    CTFontRef tfont = CTFontCreateWithName((__bridge CFStringRef)(kMainFont), 11, NULL);
    
    //setup the drawing space
    CGRect mediaBox = CGRectMake(0, 0, 612, 792);
    CGMutablePathRef tocFramePath = CGPathCreateMutable();
    
    CGPathAddRect(tocFramePath, NULL, tocFrame);
    
    CFRange currentRange = CFRangeMake(0, 0);
    
    //draw table of contents
    
    CFMutableAttributedStringRef tocText = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(tocRef));
    CFAttributedStringReplaceString(tocText, CFRangeMake(0, 0), tocRef);
    CFAttributedStringSetAttribute(tocText, CFRangeMake(0, CFAttributedStringGetLength(tocText)), kCTParagraphStyleAttributeName, pstylecenter);
    CFAttributedStringSetAttribute(tocText, CFRangeMake(0, CFAttributedStringGetLength(tocText)), kCTFontAttributeName, font);
    CTFramesetterRef tocFramesetter = CTFramesetterCreateWithAttributedString(tocText);
    CTFrameRef tocFrameRef = CTFramesetterCreateFrame(tocFramesetter, currentRange, tocFramePath, NULL);
    CGPathRelease(tocFramePath);
    
    CGContextBeginPage(context, &mediaBox);
    CTFrameDraw(tocFrameRef, context);
    CFRelease(tocFrameRef);
    CFRelease(tocText);
    CFRelease(tocFramesetter);
    
    //draw the table headers
    CGRect stFrame = CGRectMake(78, 640, 70, 25);
    CGMutablePathRef stFramePath = CGPathCreateMutable();
    CGPathAddRect(stFramePath, NULL, stFrame);
    
    NSString *st = @"Entry"; CFStringRef stRef = (__bridge CFStringRef)st;
    CFMutableAttributedStringRef stText = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(stRef));
    CFAttributedStringReplaceString(stText, CFRangeMake(0, 0), stRef);
    CFAttributedStringSetAttribute(stText, CFRangeMake(0, CFAttributedStringGetLength(stText)), kCTFontAttributeName, stfont);
    CTFramesetterRef stFramesetter = CTFramesetterCreateWithAttributedString(stText);
    CTFrameRef stFrameRef = CTFramesetterCreateFrame(stFramesetter, currentRange, stFramePath, NULL);
    CGPathRelease(stFramePath);
    CTFrameDraw(stFrameRef, context);
    CFRelease(stFramesetter);
    CFRelease(stText);
    CFRelease(stFrameRef);
    
    stFrame = CGRectMake(160, 640, 150, 25);
    stFramePath = CGPathCreateMutable();
    CGPathAddRect(stFramePath, NULL, stFrame);
    st = @"Summary"; stRef = (__bridge CFStringRef)st;
    stText = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(stRef));
    CFAttributedStringReplaceString(stText, CFRangeMake(0, 0), stRef);
    CFAttributedStringSetAttribute(stText, CFRangeMake(0, CFAttributedStringGetLength(stText)), kCTFontAttributeName, stfont);
    stFramesetter = CTFramesetterCreateWithAttributedString(stText);
    stFrameRef = CTFramesetterCreateFrame(stFramesetter, currentRange, stFramePath, NULL);
    CGPathRelease(stFramePath);
    CTFrameDraw(stFrameRef, context);
    CFRelease(stFramesetter);
    CFRelease(stText);
    CFRelease(stFrameRef);
    
    stFrame = CGRectMake(10, 640, 560, 25);
    stFramePath = CGPathCreateMutable();
    CGPathAddRect(stFramePath, NULL, stFrame);
    st = @"Date"; stRef = (__bridge CFStringRef)st;
    
    stText = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(stRef));
    CFAttributedStringReplaceString(stText, CFRangeMake(0, 0), stRef);
    CFAttributedStringSetAttribute(stText, CFRangeMake(0, CFAttributedStringGetLength(stText)), kCTFontAttributeName, stfont);
    stFramesetter = CTFramesetterCreateWithAttributedString(stText);
    stFrameRef = CTFramesetterCreateFrame(stFramesetter, currentRange, stFramePath, NULL);
    CGPathRelease(stFramePath);
    CTFrameDraw(stFrameRef, context);
    CFRelease(stText);
    CFRelease(stFramesetter);
    CFRelease(stFrameRef);
    
    //draw a line under the table headers
    CGContextSetStrokeColorWithColor(context, [UIColor activeColor].CGColor);
    CGPoint points[] = {CGPointMake(5,640),CGPointMake(607,640)};
    CGContextAddLines(context,points, 2);
    CGContextStrokePath(context);
    
    CGFloat components[4];
    [[UIColor activeColor] getRed:&components[0] green:&components[1] blue:&components[2] alpha:nil];
    
    //loop through each file, printing the file (docket) summary and the page of the docket entry
    
    CGFloat y = 635; //set y to the top of the page
    NSInteger counter = 0;
    
    for(DkTDocketEntry *entry in entries)
    {
        
        //draw the summary
        NSString *renderedSummary = [entry renderSummary].string;
        CFStringRef nameString = (__bridge CFStringRef)renderedSummary;
        CFMutableAttributedStringRef nameTextRef = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(nameString));
        CFAttributedStringReplaceString(nameTextRef, currentRange, nameString);
        CFAttributedStringSetAttribute(nameTextRef, CFRangeMake(0, CFAttributedStringGetLength(nameTextRef)), kCTFontAttributeName, tfont);
        CTFramesetterRef nameFrameSetter = CTFramesetterCreateWithAttributedString(nameTextRef);
        CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(nameFrameSetter, currentRange, NULL, CGSizeMake(450, 792), NULL);
        CGFloat height = size.height;
        CGMutablePathRef nameFramePath = CGPathCreateMutable();
        CGRect nameRect = CGRectMake(160, y-height, 450, height);
        
        //if we are at the bottom of the page, end the page and start a new one by resetting the y variable to the top of the page
        
        if(y-height < 15)
        {
            CGContextEndPage(context);
            CGContextBeginPage(context, &mediaBox);
            y=720;
            nameRect = CGRectMake(160, y-height, 450, height);
        }
        
        //draw the file entry and the file path
        CGPathAddRect(nameFramePath, NULL, nameRect);
        CTFrameRef nameFrameRef = CTFramesetterCreateFrame(nameFrameSetter, currentRange, nameFramePath, NULL);
        CTFrameDraw(nameFrameRef, context);
        CGPathRelease(nameFramePath);
        CFRelease(nameFrameRef);
        CFRelease(nameFrameSetter);
        
        if(entry.entryNumber.intValue > 0) {
            
            CFStringRef entryString = (__bridge CFStringRef)entry.entryNumber;
            CFMutableAttributedStringRef entryRef = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength((entryString)));
            CFAttributedStringReplaceString(entryRef, currentRange, entryString);
            CFAttributedStringSetAttribute(entryRef, CFRangeMake(0, CFAttributedStringGetLength(entryRef)), kCTFontAttributeName, tfont);
            CTFramesetterRef entryFramesetter = CTFramesetterCreateWithAttributedString(entryRef);
            CGMutablePathRef entryFramePath = CGPathCreateMutable();
            CGPathAddRect(entryFramePath, NULL, CGRectMake(entry.entryNumber.length > 6 ? 78 : 90, y-14, 90,14));
            CTFrameRef entryFrameRef = CTFramesetterCreateFrame(entryFramesetter, currentRange, entryFramePath, NULL);
            CTFrameDraw(entryFrameRef, context);
            CFRelease(entryFramesetter);
            CFRelease(entryFrameRef);
            CFRelease(entryRef);
            CGPathRelease(entryFramePath);
            
        }
        
        
        CFStringRef date = (__bridge CFStringRef)entry.date;
        
        
        CFMutableAttributedStringRef dateRef = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength((date)));
        CFAttributedStringReplaceString(dateRef, currentRange, date);
        CFAttributedStringSetAttribute(dateRef, CFRangeMake(0, CFAttributedStringGetLength(dateRef)), kCTFontAttributeName, tfont);
        CTFramesetterRef dateFramesetter = CTFramesetterCreateWithAttributedString(dateRef);
        CGMutablePathRef dateFramePath = CGPathCreateMutable();
        CGPathAddRect(dateFramePath, NULL, CGRectMake(10, y-14, 60,16));
        CTFrameRef dateFrameRef = CTFramesetterCreateFrame(dateFramesetter, currentRange, dateFramePath, NULL);
        CTFrameDraw(dateFrameRef, context);
        CFRelease(dateFramesetter);
        CFRelease(dateRef);
        CFRelease(dateFrameRef);
        CGPathRelease(dateFramePath);
        
        if(counter %2 == 1) {
            
            CGContextSetRGBFillColor(context, components[0], components[1], components[2],.5);
            CGRect fillRect = CGRectMake(points[0].x, nameRect.origin.y-5, points[1].x-points[0].x, nameRect.size.height+10);
            CGContextFillRect(context, fillRect);
        }
        
        y-=(nameRect.size.height+20); ++counter;
    }
    
    CFRelease(font); CFRelease(tfont); CFRelease(stfont); CFRelease(pstylecenter);
    CGContextEndPage(context);
    
    CGContextRelease(context);
    CFRelease(pdfURLOutput);
}

+(void) printDocket:(DkTDocket *)docket entries:(NSArray *)entries toPath:(NSString *)path {
    DrawDocket(docket.name, entries, path);
}

@end

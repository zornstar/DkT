
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDocumentManager.h"
#import "DkTDocket.h"
#import "DkTDocketEntry.h"
#import "ZipFile.h"
#import "ZipWriteStream.h"
#import "UIImage+Utilities.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>
#import <sys/xattr.h>

NSString* const DkTFileEntryKey = @"entry";
NSString* const DkTFileSummaryKey = @"summary";
NSString* const DkTFilePathKey = @"path";

NSString* const DkTFileDocketNameKey = @"name";
NSString* const DkTFileDocketFilesKey = @"files";
NSString* const DkTFileDocketCollapsedKey = @"collapsed";

NSString* const DkTMetadataFile = @".Documents.metadata";
NSString* const DkTHelpFileName = @"Help";


@interface DkTDocumentManager ()

@property (nonatomic, weak) id<DkTDocumentManagerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *dockets;

@end

@implementation DkTDocumentManager

+(id)sharedManager
{
    static dispatch_once_t pred;
    static DkTDocumentManager *sharedInstance = nil;
   
    
    dispatch_once(&pred, ^{
        sharedInstance = [[DkTDocumentManager alloc] init];
        sharedInstance.delegate = nil;
        NSMutableArray *dockets = [[NSMutableArray alloc] initWithContentsOfFile:[DkTDocumentManager metadataFilePath]];
        sharedInstance.dockets = dockets;
        if(sharedInstance.dockets == nil)
        {
            sharedInstance.dockets = [NSMutableArray array];
        }
    });
    
    return sharedInstance;
}
+(void) setDelegate:(id<DkTDocumentManagerDelegate>)delegate
{
    [[DkTDocumentManager sharedManager] setDelegate:delegate];
}

+(NSString *)applicationDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSUserDomainMask, YES) lastObject];
}

+(NSString *) applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+(NSString *) docketsFolder
{
    return [[DkTDocumentManager applicationDocumentsDirectory] stringByAppendingPathComponent:kDocketsFolder];
}

+(NSString *) metadataFilePath
{
    NSString *metadataPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:DkTMetadataFile];
    return metadataPath;
}

+(NSString *)temporaryDocumentsDirectory
{
    return NSTemporaryDirectory();
}

+(NSString *) helpDocumentPath
{
    return [[NSBundle mainBundle] pathForResource:DkTHelpFileName ofType:@".pdf"];
}

-(NSMutableArray *) filesInDocketNamed:(NSString *)docketName
{
    
    NSArray *array = [self.dockets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(%K == %@)", @"name", docketName]];
    
    if(array.count == 0) return nil;
    
    NSDictionary *docketDir = [array objectAtIndex:0];
    
    NSMutableArray *returnArray = [docketDir objectForKey:@"files"];
    
    return [[returnArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        
        if(floatForEntry(obj1) > floatForEntry(obj2) ) return NSOrderedDescending;
        
        else if(floatForEntry(obj1) == floatForEntry(obj2) ) return NSOrderedSame;
        
        else return NSOrderedAscending;
        
    }] mutableCopy];
}

float floatForEntry (id obj)
{
    
    NSString *s1 = [[obj objectForKey:DkTFileEntryKey] lastPathComponent];
    
    int s = [s1 rangeOfString:@"#"].location+1;
    
    float n;
    
    int e = [s1 rangeOfString:@").pdf"].location;
    
    if(e != NSNotFound)
    {
        NSString *str1 = [obj substringWithRange:NSMakeRange(s, e-s)];
        s = e;
        e = [obj rangeOfString:@")"].location;
        NSString *str2 = [obj substringWithRange:NSMakeRange(s, e-s)];
        n = [[NSString stringWithFormat:@"%@.%@", str1, str2] floatValue];
    }
    
    else
    {
        e = [obj rangeOfString:@".pdf"].location;
        n = [obj substringWithRange:NSMakeRange(s, e-s)].floatValue;
    }
    
    return n;
}

+(void) clearTempFiles
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSArray *fileArray = [manager contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    
    for (NSString *filename in fileArray)  {
        
        [manager removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:filename] error:NULL];
    }
    
}

+(NSString *)saveDocketEntry:(DkTDocketEntry *)entry atTempPath:(NSString *)tempPath
{
    NSString *summary = [[entry renderSummary] string];
    
    NSString *path = [DkTDocumentManager saveDocumentAtTempPath:tempPath toSavedDocketNamed:entry.docket.name];
    
    if(path)
    {
        
        float fileValue = entry.entryNumber.floatValue;
        if([entry isKindOfClass:[DKTAttachment class]])
        {
            fileValue += ((DKTAttachment *)entry).attachment.floatValue*.1;
        }
            
        DkTFile *file = DkTFileCreate([NSNumber numberWithFloat:fileValue], summary, path);
        [[DkTDocumentManager sharedManager] addFile:file];
    }
    
    return path;
}


-(void) addFile:(DkTFile *)file
{
    
    NSString *docketName = [[[file objectForKey:DkTFilePathKey] stringByDeletingLastPathComponent] lastPathComponent];
    docketName = decodeFromPercentEscapeString(docketName);
    NSDictionary *docketDir;
    NSArray *array = [self.dockets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(%K == %@)", DkTFileDocketNameKey, docketName]];
    
    if(array.count != 0)
    {
        docketDir = [array objectAtIndex:0];
    }
    
    else
    {
        docketDir =  DkTDocketFileCreate(docketName);
        [self.dockets addObject:docketDir];
    }
    
    NSMutableArray *files = [docketDir objectForKey:DkTFileDocketFilesKey];
    [files addObject:file];
    
    [files sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        float a = [[obj1 objectForKey:DkTFileEntryKey] floatValue];
        float b = [[obj2 objectForKey:DkTFileEntryKey] floatValue];
        
        if(a > b) return NSOrderedDescending;
        
        else if(a == b) return NSOrderedSame;
        
        else return NSOrderedAscending;
        
    }];
    
    if([self.delegate respondsToSelector:@selector(didSaveFile:)]) [self.delegate didSaveFile:file];
    [[DkTDocumentManager sharedManager] sync];
}

-(void) removeFile:(DkTFile *)file
{
    NSString *path = [file objectForKey:DkTFilePathKey];
    
    if([[NSFileManager defaultManager] removeItemAtPath:path error:nil])
    {
        NSArray *components = [path componentsSeparatedByString:@"/"];
        NSString *docketName = [components objectAtIndex:components.count -2];
        docketName = decodeFromPercentEscapeString(docketName);
        NSArray *array = [self.dockets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(%K == %@)", DkTFileDocketNameKey, docketName]];
        
        if(array.count > 0)
        {
            NSDictionary *docketDir = [array objectAtIndex:0];
            NSMutableArray *files = [docketDir objectForKey:DkTFileDocketFilesKey];
            [files removeObject:file];
            
            if(files.count == 0) [self removeDocketNamed:docketName];
        }
        
        [[DkTDocumentManager sharedManager] sync];
    }
}

-(void) removeDocketNamed:(NSString *)docketName
{
    NSString *path = [DkTDocumentManager pathToDocket:docketName];
    
    if([[NSFileManager defaultManager] removeItemAtPath:path error:nil])
    {
        docketName = decodeFromPercentEscapeString(docketName);
        NSArray *array = [self.dockets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(%K == %@)", DkTFileDocketNameKey, docketName]];
        
        if(array.count > 0)
        {
            [self.dockets removeObject:[array objectAtIndex:0]];
        }
        
        [[DkTDocumentManager sharedManager] sync];
    }
}

-(void) sync
{
    [self.dockets writeToFile:[DkTDocumentManager metadataFilePath] atomically:YES];
}

+(NSString *)saveDocumentAtTempPath:(NSString *)tempPath toSavedDocketNamed:(NSString *)name
{
    
    NSString *escapedName = encodeToPercentEscapeString(name);
    NSFileManager *manager = [NSFileManager defaultManager];
     NSError *error;
    
    NSString *lpc = [tempPath lastPathComponent];
    NSString *fileName = [[lpc componentsSeparatedByString:@"&"] lastObject];
    NSString *docketPath = [DkTDocumentManager docketsFolder];
    
    if (![manager fileExistsAtPath:docketPath])
        [manager createDirectoryAtPath:docketPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create base folder
    
    
    docketPath = [docketPath stringByAppendingPathComponent:escapedName];
    
    if (![manager fileExistsAtPath:docketPath])
        [manager createDirectoryAtPath:docketPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    
    
    docketPath = [docketPath stringByAppendingPathComponent:fileName];
    
    [manager copyItemAtPath:tempPath toPath:docketPath error:&error];
    
    if(error) return nil;
    
    else return docketPath;
}

+(NSString *) localPathForDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry
{
    NSString *docketFolder =  [DkTDocumentManager pathToDocket:docket.name];
    NSString *pathToEntry = [docketFolder stringByAppendingPathComponent:[entry fileName]];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:pathToEntry]) return pathToEntry;
    
    else return nil;
    
}

+(void) localPathForDocket:(DkTDocket *)docket entry:(DkTDocketEntry *)entry completion:(DkTLocalDocumentBlock)blk
{
    NSString *path = [DkTDocumentManager localPathForDocket:docket entry:entry];
    
    blk(entry, path);
}

+(NSString *)pathToDocket:(NSString *)docketName
{
    NSString *escapedString = encodeToPercentEscapeString(docketName);
    return [[self docketsFolder] stringByAppendingPathComponent:escapedString];
}

+(BOOL) removeDocketAtPath:(NSString *)path
{
    NSFileManager *manager = [NSFileManager defaultManager];
    return [manager removeItemAtPath:path error:nil];
}

+(BOOL) docketPathIsEmpty:(NSString *)path
{
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString *filename in dirContents) {
        if ([filename hasSuffix:@".pdf"]) {
            
            return FALSE;
        }
    }
    
    return TRUE;
}


#pragma mark - Bundling / Zipping

+(void)joinDocketNamed:(NSString *)docketName destination:(NSString *)path batchOptions:(DkTBatchOptions)options completion:(DkTBatchCompletionBlock)blk
{
    NSDate* date = [NSDate date]; NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"MM-dd-yyyy HH:MM:SS"]; NSString* str = [formatter stringFromDate:date];
    
    // File paths
    NSArray *dockets = [[DkTDocumentManager sharedManager] dockets];
    NSArray *array = [dockets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(%K == %@)", DkTFileDocketNameKey, docketName]];
    
    if(array.count == 0) return;
    
    DkTDocketFile *docketDir = [array objectAtIndex:0];
    
    NSArray *tempFiles = [docketDir objectForKey:DkTFileDocketFilesKey];
    
    NSString *uid = [docketName stringByAppendingString:[NSString stringWithFormat:@"Batch (%@)", str]];
    NSString *destPath = [[path stringByAppendingString:uid] stringByAppendingPathExtension:@"pdf"];
    CFURLRef pdfURLOutput =(__bridge_retained CFURLRef) [[NSURL alloc] initFileURLWithPath:(NSString *)destPath];//(CFURLRef)
    CGContextRef context = CGPDFContextCreateWithURL(pdfURLOutput, NULL, NULL);
    
    //insert docket page
    [formatter setDateFormat:@"MM/dd/yyyy"]; str = [formatter stringFromDate:date];
    
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)(kMainFont), 32., NULL);
    CTFontRef dfont = CTFontCreateWithName((__bridge CFStringRef)(kMainFont), 16., NULL);
    CTFontRef efont = CTFontCreateWithName((__bridge CFStringRef)(kMainFont), 18., NULL);
    CTTextAlignment center = kCTTextAlignmentCenter;
    CTTextAlignment justified = kCTTextAlignmentJustified;
    CTTextAlignment right = kCTTextAlignmentRight;
    CTParagraphStyleSetting centersettings[] = { {kCTParagraphStyleSpecifierAlignment, sizeof(center),&center} };
    CTParagraphStyleSetting justifiedsettings[] = { {kCTParagraphStyleSpecifierAlignment, sizeof(justified),&justified} };
    CTParagraphStyleSetting rightsettings[] = { {kCTParagraphStyleSpecifierAlignment, sizeof(right),&right} };
    
    CTParagraphStyleRef pstylecenter = CTParagraphStyleCreate(centersettings, sizeof(centersettings)/sizeof(centersettings[0]));
    CTParagraphStyleRef pstylejustified = CTParagraphStyleCreate(justifiedsettings, sizeof(justifiedsettings)/sizeof(justifiedsettings[0]));
    CTParagraphStyleRef pstyleright = CTParagraphStyleCreate(rightsettings, sizeof(rightsettings)/sizeof(rightsettings[0]));
    
    
    CGRect mediaBox = CGRectMake(0, 0, 612, 792);
    CGRect border = CGRectInset(mediaBox, 20, 20);
    
    
    
    //title
    CGRect titleFrame = CGRectMake(25, 500, 562, 100);
    CGMutablePathRef titleFramePath = CGPathCreateMutable();
    CGPathAddRect(titleFramePath, NULL, titleFrame);
    CFRange currentRange = CFRangeMake(0, 0);
    
    NSString *titleString = [NSString stringWithFormat:@"%@", docketName];
    CFStringRef titleStringRef = (__bridge CFStringRef)titleString;
    
    CFMutableAttributedStringRef titleText = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(titleStringRef));
    CFAttributedStringReplaceString(titleText, CFRangeMake(0, 0), titleStringRef);
    CFAttributedStringSetAttribute(titleText, CFRangeMake(0, CFAttributedStringGetLength(titleText)), kCTParagraphStyleAttributeName, pstylecenter);
    CFAttributedStringSetAttribute(titleText, CFRangeMake(0, CFAttributedStringGetLength(titleText)), kCTFontAttributeName, font);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(titleText);
    CTFrameRef titleFrameRef = CTFramesetterCreateFrame(framesetter, currentRange, titleFramePath, NULL);
    CGPathRelease(titleFramePath);
    
    
    
    
    //generated by
    
    CGRect descripFrame = CGRectMake(0, 450, 612, 20);
    CGMutablePathRef descripPath = CGPathCreateMutable();
    CGPathAddRect(descripPath, NULL, descripFrame);
    
    NSString *descripString = [NSString stringWithFormat:@"generated on %@ by", str];
    CFStringRef descripStringRef = (__bridge CFStringRef)descripString;
    
    CFMutableAttributedStringRef dText = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(descripStringRef));
    CFAttributedStringReplaceString(dText, CFRangeMake(0, 0), descripStringRef);
    CFAttributedStringSetAttribute(dText, CFRangeMake(0, CFAttributedStringGetLength(dText)), kCTParagraphStyleAttributeName, pstylecenter);
    CFAttributedStringSetAttribute(dText, CFRangeMake(0, CFAttributedStringGetLength(dText)), kCTFontAttributeName, dfont);
    
    CFRelease(framesetter);
    framesetter = CTFramesetterCreateWithAttributedString(dText);
    CTFrameRef descripFrameRef = CTFramesetterCreateFrame(framesetter, currentRange, descripPath, NULL);
    CGPathRelease(descripPath);
    
    
    
    CGContextBeginPage(context, &mediaBox);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGImageRef imgRef = [[UIImage imageNamed:@"Logo"] imageWithColor:[UIColor activeColor]].CGImage;
    CGContextDrawImage(context, CGRectMake(218, 330, 195, 99), imgRef);
    CTFrameDraw(titleFrameRef, context);
    CTFrameDraw(descripFrameRef, context);
    CGContextSetStrokeColorWithColor(context, [UIColor activeColor].CGColor);
    CGContextStrokeRect(context, border);
    CGContextEndPage(context);
    
    
    if((options & DkTBatchOptionsTOC) != 0) TableOfContents(context, tempFiles);
    
    NSInteger pageCounter = 1;
    
    for(DkTFile *file in tempFiles)
    {
        
        NSString *path = [file objectForKey:DkTFilePathKey];
        NSString *fileName = [path lastPathComponent];
        CFURLRef pdfURL = (__bridge_retained CFURLRef)[[NSURL alloc] initFileURLWithPath:path];
        CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithURL((CFURLRef) pdfURL);
        NSInteger numberOfPages = CGPDFDocumentGetNumberOfPages(pdfRef);
        CGPDFPageRef page;
        
        
        
        CGContextBeginPage(context, &mediaBox);
        
        CGRect entryFrame = CGRectMake(0, 450, 600, 100);
        CGMutablePathRef entryPath = CGPathCreateMutable();
        CGPathAddRect(entryPath, NULL, entryFrame);
        NSString *slipString = [NSString stringWithFormat:(numberOfPages > 1) ? @"%@\n\n(%d pages)" : @"%@\n\n(%d page)", [fileName stringByDeletingPathExtension], numberOfPages];
        CFStringRef entryStringRef = (__bridge CFStringRef)slipString;
        CFMutableAttributedStringRef entryText = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(entryStringRef));
        CFAttributedStringReplaceString(entryText, CFRangeMake(0, 0), entryStringRef);
        CFAttributedStringSetAttribute(entryText, CFRangeMake(0, CFAttributedStringGetLength(entryText)), kCTParagraphStyleAttributeName, pstylecenter);
        CFAttributedStringSetAttribute(entryText, CFRangeMake(0, CFAttributedStringGetLength(entryText)), kCTFontAttributeName, efont);
        CFRelease(framesetter);
        framesetter = CTFramesetterCreateWithAttributedString(entryText);
        CTFrameRef entryFrameRef = CTFramesetterCreateFrame(framesetter, currentRange, entryPath, NULL);
        CGPathRelease(entryPath);
        CTFrameDraw(entryFrameRef, context);
        CFRelease(entryFrameRef);
        
        
        
        CGRect summaryFrame = CGRectMake(20, 220, 577, 220);
        CGMutablePathRef summaryPath = CGPathCreateMutable();
        CGPathAddRect(summaryPath, NULL, summaryFrame);
        NSString *summary = [file objectForKey:DkTFileSummaryKey];
        CFStringRef summaryStringRef = (__bridge CFStringRef)summary;
        CFMutableAttributedStringRef summaryText = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(summaryStringRef));
        CFAttributedStringReplaceString(summaryText, CFRangeMake(0, 0), summaryStringRef);
        CFAttributedStringSetAttribute(summaryText, CFRangeMake(0, CFAttributedStringGetLength(summaryText)), kCTParagraphStyleAttributeName, pstylejustified);
        CFAttributedStringSetAttribute(summaryText, CFRangeMake(0, CFAttributedStringGetLength(summaryText)), kCTFontAttributeName, dfont);
        CFRelease(framesetter);
        framesetter = CTFramesetterCreateWithAttributedString(summaryText);
        CTFrameRef summaryFrameRef = CTFramesetterCreateFrame(framesetter, currentRange, summaryPath, NULL);
        CGPathRelease(summaryPath);
        CTFrameDraw(summaryFrameRef, context);
        
        
        
        if((options & DkTBatchOptionsPageNumbers) != 0) DrawPageNumber(context, pageCounter, pstyleright, efont, kActiveColor.CGColor, mediaBox);

        CGContextEndPage(context);
        
        for (int i=1; i<=numberOfPages; i++) {
            
            pageCounter++;
            page = CGPDFDocumentGetPage(pdfRef, i);
            mediaBox = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
            CGContextBeginPage(context, &mediaBox);
            CGContextDrawPDFPage(context, page);
            if((options & DkTBatchOptionsPageNumbers) != 0) DrawPageNumber(context, pageCounter, pstyleright, efont, kActiveColor.CGColor, mediaBox);
            CGContextEndPage(context);
            
        }
        
        CFRelease(summaryText);
        CFRelease(entryText);
        CFRelease(summaryFrameRef);
        CFRelease(pdfURL);
        CGPDFDocumentRelease(pdfRef);
        
        pageCounter++;
    }
    
    CFRelease(pstylecenter); CFRelease(pstylejustified); CFRelease(pstyleright);
    CFRelease(descripFrameRef); CFRelease(titleFrameRef);
    CFRelease(efont); CFRelease(titleText); CFRelease(dText); CFRelease(font); CFRelease(dfont);
    CFRelease(framesetter);
    CGContextRelease(context);
    CFRelease(pdfURLOutput);
    
    blk(destPath);
    
}

void TableOfContents(CGContextRef context, NSArray *files)
{
    CTTextAlignment center = kCTTextAlignmentCenter;
    CTParagraphStyleSetting centersettings[] = { {kCTParagraphStyleSpecifierAlignment, sizeof(center),&center} };
    CTParagraphStyleRef pstylecenter = CTParagraphStyleCreate(centersettings, sizeof(centersettings)/sizeof(centersettings[0]));
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)(kMainFont), 32., NULL);
    CTFontRef stfont = CTFontCreateWithName((__bridge CFStringRef)(kContrastFont), 12, NULL);
    CTFontRef tfont = CTFontCreateWithName((__bridge CFStringRef)(kMainFont), 14, NULL);
    
    CGRect mediaBox = CGRectMake(0, 0, 612, 792);
    
    
    CGRect tocFrame = CGRectMake(0, 650, 612, 100);
    CGMutablePathRef tocFramePath = CGPathCreateMutable();
    CGPathAddRect(tocFramePath, NULL, tocFrame);
    CFRange currentRange = CFRangeMake(0, 0);
    
    NSString *toc = @"Table Of Contents"; CFStringRef tocRef = (__bridge CFStringRef)toc;
    
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
    
    CGRect stFrame = CGRectMake(10, 630, 70, 25);
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
    
    stFrame = CGRectMake(70, 630, 70, 25);
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
    
    stFrame = CGRectMake(555, 630, 560, 25);
    stFramePath = CGPathCreateMutable();
    CGPathAddRect(stFramePath, NULL, stFrame);
    st = @"Page"; stRef = (__bridge CFStringRef)st;
    
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

    CGContextSetStrokeColorWithColor(context, [UIColor activeColor].CGColor);
    CGPoint points[] = {CGPointMake(5,640),CGPointMake(607,640)};
    CGContextAddLines(context,points, 2);
    CGContextStrokePath(context);
    
    CGFloat y = 635;
    NSInteger pageCounter = 1;
    
    
    for(DkTFile *file in files)
    {
        
        CFStringRef nameString = (__bridge CFStringRef)[file objectForKey:DkTFileSummaryKey];
        CFMutableAttributedStringRef nameTextRef = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(nameString));
        CFAttributedStringReplaceString(nameTextRef, currentRange, nameString);
        CFAttributedStringSetAttribute(nameTextRef, CFRangeMake(0, CFAttributedStringGetLength(nameTextRef)), kCTFontAttributeName, tfont);
        CTFramesetterRef nameFrameSetter = CTFramesetterCreateWithAttributedString(nameTextRef);
        CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(nameFrameSetter, currentRange, NULL, CGSizeMake(475, 792), NULL);
        CGFloat height = size.height;
        CGMutablePathRef nameFramePath = CGPathCreateMutable();
        CGRect nameRect = CGRectMake(70, y-height, 470, height);
        
        CFRelease(nameTextRef);
        
        if(y-height < 15)
        {
            CGContextEndPage(context);
            CGContextBeginPage(context, &mediaBox);
            y=685;
            nameRect = CGRectMake(65, y-height, 475, height);
        }
        
        CGPathAddRect(nameFramePath, NULL, nameRect);
        CTFrameRef nameFrameRef = CTFramesetterCreateFrame(nameFrameSetter, currentRange, nameFramePath, NULL);
        CTFrameDraw(nameFrameRef, context);
        CGPathRelease(nameFramePath);
        CFRelease(nameFrameRef);
        CFRelease(nameFrameSetter);
        
        float n = [[file objectForKey:DkTFileEntryKey] floatValue];
        NSString *fileString = [NSString stringWithFormat:@"%0.1f", n];
        CFStringRef entryString = (__bridge CFStringRef)fileString;
        CFMutableAttributedStringRef entryRef = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength((entryString)));
        CFAttributedStringReplaceString(entryRef, currentRange, entryString);
        CFAttributedStringSetAttribute(entryRef, CFRangeMake(0, CFAttributedStringGetLength(entryRef)), kCTFontAttributeName, tfont);
        CTFramesetterRef entryFramesetter = CTFramesetterCreateWithAttributedString(entryRef);
        CGMutablePathRef entryFramePath = CGPathCreateMutable();
        CGPathAddRect(entryFramePath, NULL, CGRectMake(15, y-14, 40,14));
        CTFrameRef entryFrameRef = CTFramesetterCreateFrame(entryFramesetter, currentRange, entryFramePath, NULL);
        CTFrameDraw(entryFrameRef, context);
        CFRelease(entryFramesetter);
        CFRelease(entryFrameRef);
        CFRelease(entryRef);
        CGPathRelease(entryFramePath);
        
        CFURLRef pdfURL = (__bridge_retained CFURLRef)[[NSURL alloc] initFileURLWithPath:[file objectForKey:DkTFilePathKey]];
        CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithURL((CFURLRef) pdfURL);
        NSInteger numberOfPages = CGPDFDocumentGetNumberOfPages(pdfRef);
        CFStringRef pages = (__bridge CFStringRef)[NSString stringWithFormat:@"%d",pageCounter];
        pageCounter += numberOfPages+1;
        CFRelease(pdfURL);
        CGPDFDocumentRelease(pdfRef);
        
        CFMutableAttributedStringRef pagesRef = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength((pages)));
        CFAttributedStringReplaceString(pagesRef, currentRange, pages);
        CFAttributedStringSetAttribute(pagesRef, CFRangeMake(0, CFAttributedStringGetLength(pagesRef)), kCTFontAttributeName, tfont);
        CTFramesetterRef pageFramesetter = CTFramesetterCreateWithAttributedString(pagesRef);
        CGMutablePathRef pageFramePath = CGPathCreateMutable();
        CGPathAddRect(pageFramePath, NULL, CGRectMake(560, y-14, 40,16));
        CTFrameRef pageFrameRef = CTFramesetterCreateFrame(pageFramesetter, currentRange, pageFramePath, NULL);
        CTFrameDraw(pageFrameRef, context);
        CFRelease(pageFramesetter);
        CFRelease(pagesRef);
        CFRelease(pageFrameRef);
        CGPathRelease(pageFramePath);
        
        y-=(nameRect.size.height+20);
    }
    
    CFRelease(font); CFRelease(tfont); CFRelease(stfont); CFRelease(pstylecenter);
    CGContextEndPage(context);
}

CGSize CTFrameGetSize(CTFrameRef frame)
{
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex numLines = CFArrayGetCount(lines);
    CGFloat maxWidth = 0;
    for(CFIndex i = 0; i < numLines; ++i)
    {
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, i);
        CGFloat ascent, descent, leading, width;
        width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        if(width > maxWidth) maxWidth = width;
    }
    
    CGFloat ascent, descent, leading;
    CTLineRef firstLine = (CTLineRef)CFArrayGetValueAtIndex(lines, 0);
    CTLineGetTypographicBounds(firstLine, &ascent, &descent, &leading);
    CGFloat firstLineHeight = ascent+descent+leading;
    
    CTLineRef lastLine = (CTLineRef)CFArrayGetValueAtIndex(lines, numLines-1);
    CTLineGetTypographicBounds(lastLine, &ascent, &descent, &leading);
    CGFloat lastLineHeight = ascent+descent+leading;
    
    CGPoint firstLineOrigin; CTFrameGetLineOrigins(frame, CFRangeMake(0, 1), &firstLineOrigin);
    CGPoint lastLineOrigin; CTFrameGetLineOrigins(frame, CFRangeMake(numLines-1, 1), &lastLineOrigin);
    
    CGFloat height = ABS(firstLineOrigin.y - lastLineOrigin.y)+firstLineHeight+lastLineHeight;
    
    return CGSizeMake(maxWidth, height);
    
}

void DrawPageNumber(CGContextRef context, NSInteger pageNumber, CTParagraphStyleRef alignment, CTFontRef font, CGColorRef color, CGRect mediaBox){
    
    
    CFRange currentRange = CFRangeMake(0, 0);
    CGMutablePathRef pageNumberPath = CGPathCreateMutable();
    CGPathAddRect(pageNumberPath, NULL, CGRectMake(20, 20, mediaBox.size.width-50, 20));
    NSString *pageString = [NSString stringWithFormat:@"%d", pageNumber];
    CFStringRef pageStringRef = (__bridge CFStringRef)pageString;
    CFMutableAttributedStringRef pageText = CFAttributedStringCreateMutable(kCFAllocatorDefault, CFStringGetLength(pageStringRef));
    CFAttributedStringReplaceString(pageText, CFRangeMake(0, 0), pageStringRef);
    CFAttributedStringSetAttribute(pageText, CFRangeMake(0, CFAttributedStringGetLength(pageText)), kCTParagraphStyleAttributeName, alignment);
    CFAttributedStringSetAttribute(pageText, CFRangeMake(0, CFAttributedStringGetLength(pageText)), kCTFontAttributeName, font);
    CFAttributedStringSetAttribute(pageText, CFRangeMake(0, CFAttributedStringGetLength(pageText)), kCTForegroundColorAttributeName, color);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(pageText);
    CTFrameRef pageNumberRef = CTFramesetterCreateFrame(framesetter, currentRange, pageNumberPath, NULL);
    CGPathRelease(pageNumberPath);
    CTFrameDraw(pageNumberRef, context);
    CFRelease(framesetter);
    CFRelease(pageText);
    CFRelease(pageNumberRef);

}

+(NSString *) zipDocketAtPath:(NSString *)filePath
{
    
    NSString *escapedDocketName = encodeToPercentEscapeString([filePath lastPathComponent]);
    NSString *escapedPath = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent: escapedDocketName];
    NSArray *tempFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:escapedPath error:NULL];
    
    NSString *titleString = [NSString stringWithFormat:@"%@.zip", escapedDocketName];
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:titleString];
    
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    
    ZipFile *zip = [[ZipFile alloc] initWithFileName:path mode:ZipFileModeCreate];
    
    
    for(NSString *fileName in tempFiles)
    {
        if([fileName.pathExtension isEqualToString:@"pdf"])
        {
            NSData *data = [NSData dataWithContentsOfFile:[escapedPath stringByAppendingPathComponent:fileName]];
            
            ZipWriteStream *stream= [zip writeFileInZipWithName:fileName
                                                   compressionLevel:ZipCompressionLevelBest];
            [stream writeData:data];
            [stream finishedWriting];
        }
    }
    
    [zip close];
    
    return path;
}
/*iCloud*/
 

@end

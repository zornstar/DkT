//
//  DkTPageRenderer.m
//  DkT
//
//  Created by Matthew Zorn on 9/11/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTPageRenderer.h"

@interface DkTPageRenderer ()

@property (nonatomic) BOOL active;

@end

@implementation DkTPageRenderer

- (CGRect ) paperRect
{
    if(!self.active)
    {
        return [super paperRect];
    }
    
    return UIGraphicsGetPDFContextBounds();
}

-(CGRect ) printableRect
{
    if(!self.active)
    {
        return [super printableRect];
    }
    
    return CGRectInset(self.paperRect, 20, 20);
    
}

-(NSData *) pdf
{
    self.active = YES;
    
    NSMutableData *pdf = [NSMutableData data];
    
    UIGraphicsBeginPDFContextToData(pdf, CGRectMake(0, 0, 792, 612), nil);
    
    [self prepareForDrawingPages:NSMakeRange(0, 1)];
    
    for(int i = 0; i < self.numberOfPages; ++i)
    {
        UIGraphicsBeginPDFPage();
        
        [self drawPageAtIndex:i inRect:UIGraphicsGetPDFContextBounds()];
    }
    
    UIGraphicsEndPDFContext();
    
    self.active = NO;
    
    return pdf;
}

-(NSInteger) numberOfPages
{
    return 1;
}

+(void) renderHTML:(NSString *)html toPDFPath:(NSString *)path completion:(UIPrintInteractionCompletionHandler)completion
{
    UIPrintInteractionController *printInteractionController = [UIPrintInteractionController sharedPrintController];
    
    DkTPageRenderer *renderer = [[DkTPageRenderer alloc] init];
    printInteractionController.printPageRenderer = renderer;
    UIMarkupTextPrintFormatter *markup = [[UIMarkupTextPrintFormatter alloc] init];
    markup.markupText = html;
    markup.startPage = 0;
    markup.contentInsets = UIEdgeInsetsMake(72, 72, 72, 72);
    markup.maximumContentWidth = 432;
    
    printInteractionController.printFormatter = markup;
    
    [renderer addPrintFormatter:markup startingAtPageAtIndex:0];
    
    NSData *data = [renderer pdf];
    
    completion(printInteractionController, TRUE, nil);
    
    [data writeToFile:path atomically:YES];
}

@end

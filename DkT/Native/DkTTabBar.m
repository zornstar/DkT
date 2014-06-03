//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTTabBar.h"
#import "UIImage+Utilities.h"
#import <QuartzCore/QuartzCore.h>

@interface DkTTabBar ()

@end

@implementation DkTTabBar

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (self.type == HMSegmentedControlTypeCustom) {
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            CGFloat stringHeight = roundf([titleString sizeWithFont:self.font].height);
            CGFloat y = roundf(((self.height - self.selectionIndicatorHeight) / 2) + (self.selectionIndicatorHeight - stringHeight / 2));
            CGRect frame = CGRectMake(roundf(self.segmentWidth * idx+.15*self.segmentWidth), y, roundf(.8*self.segmentWidth), stringHeight);
            
            CATextLayer *titleLayer = [CATextLayer layer];
            // Note: text inside the CATextLayer will appear blurry unless the rect values around rounded
            titleLayer.frame = frame;
            [titleLayer setFont:(__bridge CFTypeRef)(self.font.fontName)];
            [titleLayer setFontSize:self.font.pointSize];
            [titleLayer setAlignmentMode:kCAAlignmentCenter];
            [titleLayer setString:titleString];
            
            if (self.selectedSegmentIndex == idx)
                [titleLayer setForegroundColor:self.selectedTextColor.CGColor];
            else
                [titleLayer setForegroundColor:self.textColor.CGColor];
            
            [titleLayer setContentsScale:[[UIScreen mainScreen] scale]];
            [self.layer addSublayer:titleLayer];
            
            frame = CGRectMake(0, stringHeight/2.-roundf(.1*self.segmentWidth)/2., roundf(.1*self.segmentWidth), roundf(.1*self.segmentWidth));
            UIImage *image = [self.sectionImages objectAtIndex:idx];
            
            image = [image imageWithColor:(self.selectedSegmentIndex == idx) ? [UIColor lighterTextColor] : [UIColor darkerTextColor]];
            
            
            CALayer *imageLayer = [CALayer layer];
            imageLayer.contents = (id)[image CGImage];
            imageLayer.frame = frame;
            [titleLayer addSublayer:imageLayer];
            
            if(idx != 0)
            {
                CALayer *rightBorder = [CALayer layer];
                rightBorder.backgroundColor = [UIColor blackColor].CGColor;
                rightBorder.opacity = .4;
                rightBorder.frame = CGRectMake(self.segmentWidth * idx - 1, 0, 1, self.layer.frame.size.height);
                
                [self.layer addSublayer:rightBorder];
            }
            
            if(self.selectedSegmentIndex != idx)
            {
                CALayer *bottomBorder = [CALayer layer];
                bottomBorder.borderColor = [UIColor blackColor].CGColor;
                bottomBorder.opacity = .4;
                bottomBorder.borderWidth = 1;
                bottomBorder.frame = CGRectMake(self.segmentWidth * idx, self.layer.frame.size.height-1, self.segmentWidth, 1);
                
                [self.layer addSublayer:bottomBorder];
            }
            
        }];
    }
}


@end

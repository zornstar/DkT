//
//  FSButton.m
//  DkTp
//
//  Created by Matthew Zorn on 6/1/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "FSButton.h"
#import "UIImage+Utilities.h"
#import <QuartzCore/QuartzCore.h>

@interface FSButton ()
{
    FSButtonSelectionBlock _selectionBlock;
}
@end

@implementation FSButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+(FSButton *)buttonWithIcon:(UIImage *)icon colors:(NSArray *)colors title:(NSString *)title actionBlock:(FSButtonSelectionBlock)block
{
    FSButton *button = [FSButton buttonWithType:UIButtonTypeCustom];
    
    [button configureButtonWithIcon:icon colors:colors title:title actionBlock:block];
    
    
    return button;
}

-(void)configureButtonWithIcon:(UIImage *)icon colors:(NSArray *)colors title:(NSString *)title actionBlock:(FSButtonSelectionBlock)block
{
    [self addTarget:self action:@selector(performAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self setSelectionBlock:block];
    
    UIColor *backgroundColor = (colors.count > 0) ? [colors objectAtIndex:0] : [UIColor clearColor];
    UIColor *foregroundColor = (colors.count > 1) ? [colors objectAtIndex:1] : [UIColor whiteColor];
    
    self.showsTouchWhenHighlighted = NO;
    [self setBackgroundColor:backgroundColor];
    [self setTitle:title forState:UIControlStateNormal];
    
    UIImage *img = [icon imageWithColor:foregroundColor];
    [self setTitleColor:foregroundColor forState:UIControlStateNormal];
    [self setTitleColor:foregroundColor forState:UIControlStateSelected];
    [self setImage:img forState:UIControlStateNormal];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if(img)
    {
        CGFloat spacing = 10;
        self.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, spacing);
        self.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
    }
}

-(void) performAction:(id)sender
{
    _selectionBlock();
}

-(void) setCornerRadius:(CGFloat)cornerRadius
{
    self.layer.cornerRadius = cornerRadius;
    self.cornerRadius = cornerRadius;
}

-(void) setIconSpacing:(CGFloat)iconSpacing
{
    self.iconSpacing = iconSpacing;
    self.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, iconSpacing);
    self.titleEdgeInsets = UIEdgeInsetsMake(0, iconSpacing, 0, 0);
    
    [self setNeedsDisplay];
}

-(void) setImageSize:(CGFloat)imageSize
{
    CGFloat scale = self.titleLabel.font.pointSize / self.imageView.frame.size.height;
    
    self.imageView.transform = CGAffineTransformMakeScale(imageSize * scale, imageSize * scale);
}

-(void) setSelectionBlock:(FSButtonSelectionBlock)blk
{
    _selectionBlock = blk;
}


-(void) invert
{
    NSArray *colors = @[[self titleColorForState:UIControlStateNormal],self.backgroundColor];
    UIImage *image = [self imageForState:UIControlStateNormal];
    NSString *title = [self titleForState:UIControlStateNormal];
    
    [self configureButtonWithIcon:image colors:colors title:title actionBlock:_selectionBlock];
}
@end

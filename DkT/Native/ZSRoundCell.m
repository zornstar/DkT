//  Created by Matthew Zorn on 8/23/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "ZSRoundCell.h"
#import <QuartzCore/QuartzCore.h>

@interface ZSRoundCell ()

@end

@implementation ZSRoundCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

-(void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self setCornerRounding:self.cornerRounding];
}

-(void) setCornerRounding:(UIRectCorner)cornerRounding
{
    _cornerRounding = cornerRounding;
    
    if(_cornerRounding != 0)
    {
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                       byRoundingCorners:self.cornerRounding
                                                             cornerRadii:CGSizeMake(self.cornerRadius, self.cornerRadius)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = self.bounds;
        maskLayer.path = maskPath.CGPath;
        self.layer.mask = maskLayer;

    }
    
    else self.layer.mask = nil;
    
}

@end

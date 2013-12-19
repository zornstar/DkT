//
//  FSPanelTab.m
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "FSPanelTab.h"
#import "UIImage+Utilities.h"

@interface FSPanelTab ()

@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation FSPanelTab

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    int width = floor(rect.size.width*2/3);
    int arclength = rect.size.width - width;
    
    self.imageView.frame = CGRectMake(rect.origin.x, rect.origin.y, width, width);
    [self addSubview:self.imageView];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextBeginPath(ctx);
    CGContextAddArc(ctx, width, rect.size.height/2., arclength, -M_PI_2, M_PI_2, 0);
    CGContextClosePath(ctx); // could be omitted
    CGContextSetFillColorWithColor(ctx, [[self.colors objectAtIndex:0] CGColor]);
    CGContextFillPath(ctx);
    
}

-(id) initWithIcon:(UIImage *)icon colors:(NSArray *)colors
{
    if(self = [super init])
    {
        _icon = [icon imageWithColor:[colors lastObject]];
        _colors = colors;
        self.imageView = [[UIImageView alloc] initWithImage:_icon];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [self.colors objectAtIndex:0];
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

@end

//
//  RECAPSettingsCell.m
//  RECAPp
//
//  Created by Matthew Zorn on 6/25/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSettingsCell.h"
#import "UIImage+Utilities.h"
#import <QuartzCore/QuartzCore.h>

@interface DkTSettingsCell ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation DkTSettingsCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.inverted = NO;
        
    #define kLabelFontSize 14
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width/4., self.contentView.frame.size.width/6., self.contentView.frame.size.width/2, self.contentView.frame.size.height/3.)];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.imageView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor activeColor];
        self.layer.cornerRadius = 5.0;
        [self.contentView addSubview:self.imageView];
        
        CGFloat y = CGRectGetMaxY(self.imageView.frame);
        
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.imageView.frame), self.contentView.frame.size.width, self.contentView.frame.size.height - y)];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.font = [UIFont fontWithName:kMainFont size:kLabelFontSize];
        self.label.textColor = [UIColor inactiveColor];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.numberOfLines = 1;
        
        [self.contentView addSubview:self.label];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self setImage:nil];
    [self setLabel:nil];
}

-(void) setImage:(UIImage *)image
{
    self.imageView.image = image;
}

-(void) setInverted:(BOOL)inverted
{
    _inverted = inverted;
    self.backgroundColor = (inverted) ?  [UIColor inactiveColor] : [UIColor activeColor];
    self.label.textColor = (inverted) ? [UIColor activeColor] : [UIColor inactiveColor];
    [self setImage:[self.imageView.image imageWithColor:(inverted) ? [UIColor activeColor] : [UIColor inactiveColor]]];

    
}

@end

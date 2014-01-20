
//  Created by Matthew Zorn on 7/14/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTAlertView.h"
#import <QuartzCore/QuartzCore.h>

@implementation DkTAlertView


-(id) initWithTitle:(NSString *)title andMessage:(NSString *)message
{
    if(self = [super initWithTitle:title andMessage:message])
    {
        self.backgroundStyle = SIAlertViewBackgroundStyleSolid;
    }
    
    return self;
}
- (void)setButtonColor:(UIColor *)buttonColor
{
    if (_buttonColor == buttonColor) {
        return;
    }
    _buttonColor = buttonColor;
    
    for (UIButton *button in self.buttons) {
        button.backgroundColor = _buttonColor;
    }
}

- (void)setButtonCornerRadius:(CGFloat)buttonCornerRadius
{
    if (_buttonCornerRadius == buttonCornerRadius) {
        return;
    }
    _buttonCornerRadius = buttonCornerRadius;
    
    for (UIButton *button in self.buttons) {
        button.layer.cornerRadius = _buttonCornerRadius;
        button.clipsToBounds = YES;
    }
}

- (UIButton *)buttonForItemIndex:(NSUInteger)index
{
    NSString *title = [self.items[index] title];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.tag = index;
	button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.titleLabel.font = self.buttonFont;
    [button setBackgroundColor:self.buttonColor]; //mz
    [button.layer setCornerRadius:self.cornerRadius];
	[button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:0.4 alpha:1] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:0.4 alpha:0.8] forState:UIControlStateHighlighted];
    
	[button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    
    return button;
}


@end

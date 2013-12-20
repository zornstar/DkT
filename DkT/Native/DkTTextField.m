//
//  DkTTextField.m
//  DkT
//
//  Created by Matthew Zorn on 7/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTTextField.h"
#import "PSMenuItem.h"

@implementation DkTTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    return self;
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self.nextResponder touchesBegan:touches withEvent:event];
}

-(BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
   
    for(PSMenuItem *item in [[UIMenuController sharedMenuController] menuItems])
    {
        [item setEnabled:NO];
    }
    
    NSLog(@"%@", [[[UIMenuController sharedMenuController] menuItems] description]);
    
    if ([UIMenuController sharedMenuController]) {
        
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:NO];
    }
    
    return NO;
}

@end

//
//  Created by Matthew Zorn on 6/23/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTView.h"
#import "PSMenuItem.h"

@implementation DkTView

-(id) initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(BOOL) canBecomeFirstResponder { return YES; }

-(BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
    
    NSString *selectorString = NSStringFromSelector(action);
    return ([selectorString rangeOfString:@"ps_"].location != NSNotFound);
    
}
@end

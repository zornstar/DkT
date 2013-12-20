//
//  Created by Matthew Zorn on 7/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSearchTableView.h"

@implementation DkTSearchTableView

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self.nextResponder touchesBegan:touches withEvent:event];
}

@end

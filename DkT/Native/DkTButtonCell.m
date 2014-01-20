
//
//  Created by Matthew Zorn on 10/5/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTButtonCell.h"

@implementation DkTButtonCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
   
    if(self.buttonView.frame.size.width > 0) {
        CGRect fr = self.textLabel.frame;
        fr.size.width = CGRectGetMinX(self.buttonView.frame);
        self.textLabel.frame = fr;
    }
    
}

@end

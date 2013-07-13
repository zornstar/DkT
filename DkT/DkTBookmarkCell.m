//
//  RECAPBookmarkCell.m
//  RECAPp
//
//  Created by Matthew Zorn on 6/2/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTBookmarkCell.h"
#import "FSButton.h"

@implementation DkTBookmarkCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) setButtons:(NSArray *)buttons
{
    for(UIView *subview in self.accessoryView.subviews)
    {
        [subview removeFromSuperview];
    }
    
    CGFloat x = 0;
    CGFloat buttonHeight = self.accessoryView.frame.size.height/2;
    CGFloat y = self.accessoryView.center.y - buttonHeight/2.0;
    
    for(UIButton *button in buttons)
    {
        button.frame = CGRectMake(x, y, buttonHeight, buttonHeight);
        x = CGRectGetMaxX(button.frame) + buttonHeight*.1;
        [self.accessoryView addSubview:button];
    }
}
@end

//
//  RECAPNumberedCell.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/27/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTNumberedCell.h"

@implementation DkTNumberedCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _numberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.imageView addSubview:_numberLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) setNumber:(NSInteger)number
{
    _number = number;
    self.numberLabel.frame = self.imageView.frame;
    self.numberLabel.text = [NSString stringWithFormat:@"%d",number];
}
@end

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
       // self.imageView.image = [[UIImage alloc] init];
        self.indentationWidth = 20.;
        self.indentationLevel = 1.;
        _numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 22, 80)];
        _numberLabel.adjustsFontSizeToFitWidth = YES;
        _numberLabel.numberOfLines = 1;
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        _numberLabel.font = [UIFont fontWithName:kMainFont size:12];
         _numberLabel.textColor = [UIColor activeColor];
        _numberLabel.backgroundColor = [UIColor clearColor];
        
        [self addSubview:_numberLabel];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

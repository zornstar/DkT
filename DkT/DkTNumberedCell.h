//
//  RECAPNumberedCell.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/27/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DkTNumberedCell : UITableViewCell

@property (nonatomic) NSInteger number;
@property (nonatomic, strong) UILabel *numberLabel;
@end

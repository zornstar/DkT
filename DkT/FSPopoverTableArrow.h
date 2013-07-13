//
//  FSPopoverTableView.h
//  DkTp
//
//  Created by Matthew Zorn on 6/2/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {FSPopoverTableArrowDirectionUp, FSPopoverTableArrowDirectionRight} FSPopoverTableArrowDirection;
@interface FSPopoverTableArrow : UIView

@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic) CGFloat arrowLength;
@property (nonatomic) FSPopoverTableArrowDirection direction;

@end

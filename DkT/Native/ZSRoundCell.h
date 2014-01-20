//  Created by Matthew Zorn on 8/23/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBadgedCell.h" //https://github.com/tmdvs/TDBadgedCell


@interface ZSRoundCell : TDBadgedCell

@property (nonatomic) UIRectCorner cornerRounding;
@property (nonatomic) CGFloat cornerRadius;

@end

@interface ZSCellBackgroundView : UIView

@property (nonatomic) UIRectCorner cornerRounding;
@property (nonatomic) CGFloat cornerRadius;

@end
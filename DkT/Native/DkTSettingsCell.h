//
//  RECAPSettingsCell.h
//  RECAPp
//
//  Created by Matthew Zorn on 6/25/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {DkTSettingsIconPositionTopLeft = 0,
    DkTSettingsIconPositionTopRight,
    DkTSettingsIconPositionBottomLeft,
    DkTSettingsIconPositionBottomRight }

DkTSettingsIconPosition;

@interface DkTSettingsCell : UICollectionViewCell

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic) BOOL inverted;

-(void) setImage:(UIImage *)image;


@end

//
//  FSButton.h
//  DkTp
//
//  Created by Matthew Zorn on 6/1/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^FSButtonSelectionBlock)();

@interface FSButton : UIButton

+(FSButton *) buttonWithIcon:(UIImage*)icon colors:(NSArray *)array title:(NSString *)title actionBlock:(FSButtonSelectionBlock)block;

-(void) setImageSize:(CGFloat)imgSize;
-(void) invert;

@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic, readonly, getter = isHighlighted) BOOL highlighted;
@property (nonatomic) CGFloat iconSpacing;
@property (nonatomic) CGFloat imageSize;

@end

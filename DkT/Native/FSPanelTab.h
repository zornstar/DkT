//
//  FSPanelTab.h
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FSPanelTab : UIControl

-(id) initWithIcon:(UIImage *)icon colors:(NSArray *)colors;

@property (nonatomic, strong, readonly) UIImage *icon;
@property (nonatomic, strong, readonly) NSArray *colors;
@end

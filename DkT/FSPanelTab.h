//
//  FSPanelTab.h
//  DkTp
//
//  Created by Matthew Zorn on 6/24/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FSPanelTab : UIControl

-(id) initWithIcon:(UIImage *)icon colors:(NSArray *)colors;

@property (nonatomic, strong, readonly) UIImage *icon;
@property (nonatomic, strong, readonly) NSArray *colors;
@end

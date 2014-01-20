
//  Created by Matthew Zorn on 7/14/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "SIAlertView.h"

@interface DkTAlertView : SIAlertView


@property (nonatomic, strong) UIColor *buttonColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; //mz
@property (nonatomic) CGFloat buttonCornerRadius NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;

@end

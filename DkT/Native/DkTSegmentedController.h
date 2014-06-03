//
//  SegmentedController.h
//  DkT
//
//  Created by Matthew Zorn on 3/23/14.
//  Copyright (c) 2014 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DkTSegmentedController : UIViewController

@property (nonatomic, retain, readonly) NSArray * viewControllers;
@property (nonatomic, retain, readonly) UIViewController * currentViewController;


@end

//
//  RECAPUtils.h
//  RECAPp
//
//  Created by Matthew Zorn on 5/25/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZUtils : NSObject

+(void) performSelectorAsync:(SEL)selector withTarget:(id)target completion:(void(^)(void))completionHandler;

CGRect CGRectConstruct(CGPoint origin, CGSize size);

CGPoint CenterRect(CGRect rect);
@end

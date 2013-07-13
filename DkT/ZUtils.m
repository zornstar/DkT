//
//  RECAPUtils.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/25/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "ZUtils.h"
#import <objc/message.h>

@implementation ZUtils

+(void) performSelectorAsync:(SEL)selector withTarget:(id)target completion:(void(^)(void))completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if([target respondsToSelector:selector])
        {
            objc_msgSend(target, selector);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler();
            });
        }
    });
}

CGRect CGRectContruct(CGPoint origin, CGSize size){
    
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

CGPoint CenterRect(CGRect rect)
{
    return CGPointMake( rect.origin.x + rect.size.height/2.0, rect.origin.y + rect.size.height/2.0);
}

@end

//
//  DkTImageCache.h
//  DkT
//
//  Created by Matthew Zorn on 10/13/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DkTImageCache : NSCache

+(id) sharedCache;
-(UIImage *) imageNamed:(NSString *)string color:(UIColor *)color;

@end

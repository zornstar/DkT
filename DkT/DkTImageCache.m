//
//  DkTImageCache.m
//  DkT
//
//  Created by Matthew Zorn on 10/13/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTImageCache.h"
#import "UIImage+Utilities.h"
@interface DkTImageCache ()

@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation DkTImageCache

+(id)sharedCache
{
    static dispatch_once_t pred;
    static DkTImageCache *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[DkTImageCache alloc] init];
        
    });
    return sharedInstance;
}

-(UIImage *) imageNamed:(NSString *)string color:(UIColor *)color
{
    UIImage *img;
    NSString *hash = [self hashStringForImage:string color:color];
    if ( (img = [self objectForKey:hash]) ) return img;
    
    NSString *pathForResource = [[NSBundle mainBundle] pathForResource:string ofType:@"png"];
    img = [[UIImage imageWithContentsOfFile:pathForResource] imageWithColor:color];
    [self setObject:img forKey:hash cost:0];
    return img;
}

-(NSString *) hashStringForImage:(NSString *)string color:(UIColor *)color
{
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    NSString *colorAsString = [NSString stringWithFormat:@"%f_%f_%f_%f_%@", components[0], components[1], components[2], components[3], string];
    return colorAsString;
}
@end

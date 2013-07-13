//
//  NSString+Utilities.m
//  DkTp
//
//  Created by Matthew Zorn on 6/23/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "NSString+Utilities.h"

@implementation NSString (Utilities)

-(BOOL) isPDF
{
    return [[self pathExtension] isEqualToString:@"pdf"];
}
@end

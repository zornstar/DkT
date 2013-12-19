//
//  NSString+Utilities.m
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "NSString+Utilities.h"

@implementation NSString (Utilities)

-(BOOL) isPDF
{
    return [[self pathExtension] isEqualToString:@"pdf"];
}

-(BOOL) isNumber
{
    NSScanner *sc = [NSScanner scannerWithString: self];
    
    if ( [sc scanFloat:nil] )
    {
        return [sc isAtEnd];
    }
    
    return NO;
}

+(NSString *) randomStringWithLength:(NSInteger)l
{
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:l];
    for (NSUInteger i = 0U; i < 20; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    
    return [NSString stringWithString:s];
}
@end

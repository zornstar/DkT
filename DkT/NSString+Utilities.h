//
//  NSString+Utilities.h
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Utilities)

-(BOOL) isPDF;
-(BOOL) isNumber;
+(NSString *) randomStringWithLength:(NSInteger)l;

@end

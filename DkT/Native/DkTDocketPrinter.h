//
//  DkTDocketPrinter.h
//  DkT
//
//  Created by Matthew Zorn on 3/23/14.
//  Copyright (c) 2014 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DkTDocket;

@interface DkTDocketPrinter : NSObject

+(void) printDocket:(DkTDocket *)docket entries:(NSArray *)entries toPath:(NSString *)path;

@end

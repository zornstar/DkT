//
//  DkTUser.m
//  DkTp
//
//  Created by Matthew Zorn on 5/19/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTUser.h"

@implementation DkTUser

-(BOOL) isEqual:(id)object
{
    if([object isKindOfClass:[self class]])
    {
        return [((DkTUser *)object).username isEqualToString:self.username] && [((DkTUser *)object).password isEqualToString:self.password];
    }
                  
    else return NO;
}
@end

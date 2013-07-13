//
//  DkTReceiptController.h
//  DkTp
//
//  Created by Matthew Zorn on 7/9/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DkTReceiptExecutionBlock)();

@interface DkTReceiptController : NSObject

+(void) promptReceiptWithCost:(float)cost yes:(DkTReceiptExecutionBlock)yesBlock no:(DkTReceiptExecutionBlock)noBlock;
                              
@end

@interface DkTAlertReceiptDelegateObject : NSObject <UIAlertViewDelegate>

@property (copy) DkTReceiptExecutionBlock yes;
@property (copy) DkTReceiptExecutionBlock no;

@end

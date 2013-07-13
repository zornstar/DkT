//
//  DkTReceiptController.m
//  DkTp
//
//  Created by Matthew Zorn on 7/9/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTReceiptController.h"

@implementation DkTReceiptController

+(void) promptReceiptWithCost:(float)cost yes:(DkTReceiptExecutionBlock)yesBlock no:(DkTReceiptExecutionBlock)noBlock
{
    DkTAlertReceiptDelegateObject *delegate = [[DkTAlertReceiptDelegateObject alloc] init];
    delegate.yes = yesBlock;
    delegate.no = noBlock;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Download Document" message:[NSString stringWithFormat:@"Download document for %f.", cost] delegate:delegate cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alertView show];
}
@end

@implementation DkTAlertReceiptDelegateObject

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
        self.no();
    }
    
    else
    {
        self.yes();
    }
}

@end

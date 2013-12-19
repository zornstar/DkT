//
//  DkTBookmarkDetailViewController.m
//  DkT
//
//  Created by Matthew Zorn on 8/15/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTBookmarkDetailViewController.h"

@interface DkTBookmarkDetailViewController ()

@end

@implementation DkTBookmarkDetailViewController

-(void) dismiss
{
    
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
        
        }];
}

@end

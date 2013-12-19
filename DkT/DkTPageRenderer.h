//
//  DkTPageRenderer.h
//  DkT
//
//  Created by Matthew Zorn on 9/11/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DkTPageRenderer : UIPrintPageRenderer

+(void) renderHTML:(NSString *)html toPDFPath:(NSString *)path completion:(UIPrintInteractionCompletionHandler)completion;

@end

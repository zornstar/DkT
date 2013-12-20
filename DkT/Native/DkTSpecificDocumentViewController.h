//
//  DkTSealedDocumentViewController.h
//  DkT
//
//  Created by Matthew Zorn on 7/14/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {DkTCustomDocumentViewControllerType, DkTSealedDocumentViewControllerType, DkTErrorDocumentViewControllerType, DkTNoDocumentViewControllerType} DkTDocumentViewControllerType;
@class DkTDocketEntry;

@interface DkTSpecificDocumentViewController : UIViewController

@property (nonatomic, strong) DkTDocketEntry *entry;

- (id)initWithType:(DkTDocumentViewControllerType)type;

@end

//
//  FSPopoverTableViewController.h
//  DkTp
//
//  Created by Matthew Zorn on 6/1/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^FSPopoverTableViewSelectionBlock)(int);

@interface FSPopoverTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

-(id) initWithAnchorView:(UIView *)view frame:(CGRect)rect selectionBlock:(FSPopoverTableViewSelectionBlock)block;
-(void) present;

@property (nonatomic, strong) UIView *anchorView;
@property (nonatomic) CGRect frame;
@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSArray *colors;
@property (readwrite, copy) FSPopoverTableViewSelectionBlock selectionBlock;
@property (nonatomic) NSTextAlignment alignment;
@property (nonatomic) CGPoint center;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *separatorColor;
@property (nonatomic) CGFloat arrowLength;

@end

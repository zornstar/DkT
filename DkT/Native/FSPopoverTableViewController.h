//
//  FSPopoverTableViewController.h
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^FSPopoverTableViewSelectionBlock)(int);

@interface FSPopoverTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

-(id) initWithAnchorView:(UIView *)view frame:(CGRect)rect selectionBlock:(FSPopoverTableViewSelectionBlock)block;
-(void) present;
-(void) reloadData;

@property (nonatomic, strong, readonly) UIView *anchorView;
@property (nonatomic) CGRect frame;
@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSArray *colors;
@property (copy) FSPopoverTableViewSelectionBlock selectionBlock;
@property (nonatomic) NSTextAlignment alignment;
@property (nonatomic) CGPoint center;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *separatorColor;
@property (nonatomic) CGFloat arrowLength;

@end

typedef enum {FSPopoverTableArrowDirectionUp, FSPopoverTableArrowDirectionRight} FSPopoverTableArrowDirection;

@interface FSPopoverTableArrow : UIView

@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic) CGFloat arrowLength;
@property (nonatomic) FSPopoverTableArrowDirection direction;

@end

//
//  FSPopoverTableViewController.m
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "FSPopoverTableViewController.h"

@interface FSPopoverTableViewController ()
{
    UIView *_shadowView;
    UIView *_containerView;
    FSPopoverTableArrow *_arrow;
}

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation FSPopoverTableViewController

- (id)initWithAnchorView:(UIView *)view frame:(CGRect)rect selectionBlock:(FSPopoverTableViewSelectionBlock)block
{
    self = [super init];
    if (self) {
        _anchorView = view;
        self.center = view.center;
        self.frame = rect;
        self.alignment = NSTextAlignmentCenter;
        self.selectionBlock = block;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect frame = self.frame;
    frame.origin = CGPointMake(self.frame.origin.x, self.frame.origin.y-self.arrowLength);
    frame.size.height =  MIN(self.frame.size.height, self.data.count * self.tableView.rowHeight) + self.arrowLength;
    _containerView = [[UIView alloc] initWithFrame:frame];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.arrowLength, self.frame.size.width, frame.size.height - self.arrowLength) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorColor = self.separatorColor;
    self.tableView.rowHeight = 45.0;
    self.tableView.layer.cornerRadius = 5.0;
    self.tableView.layer.borderWidth = 2.0;
    self.tableView.layer.borderColor = self.borderColor.CGColor;
    self.tableView.bounces = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    if([self.tableView respondsToSelector:@selector(separatorInset)]) self.tableView.separatorInset = UIEdgeInsetsZero;
    _arrow = [[FSPopoverTableArrow alloc] initWithFrame:CGRectMake(self.frame.size.width/2.-self.arrowLength/2., self.tableView.layer.borderWidth, self.arrowLength, self.arrowLength)];
    _arrow.arrowColor = [self.colors objectAtIndex:1];
    _arrow.arrowLength = self.arrowLength;
    _arrow.layer.borderWidth = 2.0;
    _arrow.layer.borderColor = self.borderColor.CGColor;
    
	
    
    _shadowView = [[UIView alloc] initWithFrame:self.tableView.frame];
    _shadowView.layer.shadowColor = [[UIColor blackColor] CGColor];
    _shadowView.layer.shadowOpacity = .5;
    _shadowView.layer.cornerRadius = 5.0;
    _shadowView.layer.shadowOffset = CGSizeMake(5,5);
    _shadowView.layer.backgroundColor = [UIColor colorWithWhite:0 alpha:.5].CGColor;
    
    
    
    self.view = [[UIView alloc] initWithFrame:self.anchorView.frame];
    [self.view addSubview:_containerView];
    
    [_containerView addSubview:_shadowView];
    [_containerView addSubview:self.tableView];
    [_containerView addSubview:_arrow];
    
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) reloadData
{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [self.tableView reloadData];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.data.count; }

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textAlignment = self.alignment;
        cell.textLabel.textColor = [self.colors objectAtIndex:0];
        cell.textLabel.font = self.font;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.textLabel.text = [self.data objectAtIndex:indexPath.row];

    
    cell.contentView.backgroundColor = ( (indexPath.row % 2) && (self.colors.count > 2) ) ? [self.colors objectAtIndex:2] : [self.colors objectAtIndex:1];
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.selectionBlock)
    {
        self.selectionBlock((int)indexPath.row);
    }
    
    [self hide];
    
}

-(void) present
{
    [self.anchorView addSubview:self.view];
    [self.view bringSubviewToFront:_arrow];
    
    CGFloat height = MIN(self.frame.size.height, self.data.count * self.tableView.rowHeight) + self.arrowLength;
    CGRect start = _containerView.frame;
    start.size.height = 0; _containerView.frame = start; CGRect frame = _containerView.frame;
    frame.size.height += height + 25;
    
    CGRect tableViewStart = _tableView.frame;
    tableViewStart.size.height = 0;
    _tableView.frame = tableViewStart;
    _shadowView.frame = tableViewStart;
    CGRect tableViewFrame = _tableView.frame;
    tableViewFrame.size.height += height;
    
    [UIView animateWithDuration:.2
                     animations:^{
                         
                         _containerView.frame = frame;
                         _tableView.frame = tableViewFrame;
                         _shadowView.frame = tableViewFrame;
                     }
                     completion:^(BOOL finished){
                         
                         
                       
                     }];
     
}

-(void) hide
{
    [self.view removeFromSuperview];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.tableView];
    
    if(![self.tableView pointInside:point withEvent:event])
    {
        [self hide];
    }
    else
    {
        [super touchesBegan:touches withEvent:event];
    }
}

@end

@implementation FSPopoverTableArrow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height+1)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.direction = FSPopoverTableArrowDirectionUp;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    
    CGPoint points[3] = { CGPointMake(0, rect.size.height-1), CGPointMake(rect.size.width/2., 0), CGPointMake(rect.size.width, rect.size.height-1) };
    
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, points[2].x, points[2].y);
    CGContextAddLineToPoint(ctx, points[0].x, points[0].y);
    CGContextSetLineWidth(ctx, self.layer.borderWidth+1);
    CGContextSetStrokeColorWithColor(ctx, self.arrowColor.CGColor);
    //CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
    CGContextStrokePath(ctx);
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, points[0].x, points[0].y);
    CGContextAddLineToPoint(ctx, points[1].x, points[1].y);
    CGContextAddLineToPoint(ctx, points[2].x, points[2].y);
    CGContextAddLineToPoint(ctx, points[0].x, points[0].y);
    CGContextSetFillColorWithColor(ctx, self.arrowColor.CGColor);
    CGContextFillPath(ctx);
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, points[0].x, points[0].y);
    CGContextAddLineToPoint(ctx, points[1].x, points[1].y);
    CGContextAddLineToPoint(ctx, points[2].x, points[2].y);
    CGContextSetLineWidth(ctx, self.layer.borderWidth);
    CGContextSetStrokeColorWithColor(ctx, self.layer.borderColor);
    CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
    CGContextStrokePath(ctx);
    
    
    
    self.layer.borderWidth = 0.0;
    self.transform = CGAffineTransformMakeRotation(self.direction * M_PI_2);
    
    
}


@end


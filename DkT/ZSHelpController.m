//
//  Created by Matthew Zorn on 6/29/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "ZSHelpController.h"
#import <objc/runtime.h>
#import "JRSwizzle.h"
#import <QuartzCore/QuartzCore.h>


NSString *const kZSHelpTextKey = @"kZSHelpTextKey";
NSString *const kZSAttributedHelpTextKey = @"kZSAttributedHelpTextKey";


@interface ZSHelpController ()

@property (nonatomic) unsigned hit;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIImageView *helpImageView;
@property (nonatomic, strong) ZSArrow *arrow;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic) CGPoint point;

@end

@implementation UIView (Help)

-(void) setAttributedHelpText:(NSAttributedString *)attributedHelpText
{
    objc_setAssociatedObject(self, (__bridge const void *)(kZSAttributedHelpTextKey), attributedHelpText, OBJC_ASSOCIATION_COPY);
}

-(NSAttributedString *) attributedHelpText
{
    return objc_getAssociatedObject(self, (__bridge const void *)(kZSAttributedHelpTextKey));
}

-(void) setHelpText:(NSString *)helpText
{
    objc_setAssociatedObject(self, (__bridge const void *)(kZSHelpTextKey), helpText, OBJC_ASSOCIATION_COPY);
}

-(NSString *) helpText
{
    return objc_getAssociatedObject(self, (__bridge const void *)(kZSHelpTextKey));
}

-(BOOL) zshc_pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    ZSHelpController *help = [ZSHelpController sharedHelpController];
    
    BOOL pointInside = [self zshc_pointInside:point withEvent:event];
    
    if(help.enabled  && pointInside && (help.hit == 0))
    {
        
        if( (self.attributedHelpText.length > 0) || (self.helpText.length > 0) )
        {
            
            UIView *targetView = [UIApplication sharedApplication].keyWindow;
            
            help.targetView = targetView;
            help.callerView = self;
            CGPoint origin;
            
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                origin = [targetView convertPoint:point fromView:self];
            else
            {
                CGPoint pt = [targetView convertPoint:point fromView:self];
                CGSize screenSize = [[UIScreen mainScreen] bounds].size;
                CGFloat x = (pt.x > screenSize.width/2.) ? screenSize.width : 0;
                CGFloat y = (pt.y > screenSize.width/4.) ? 0 : screenSize.width/2.;
                
                origin = CGPointMake(x, y); 
            }
            
            if(self.attributedHelpText.length > 0) [ZSHelpController showAtPoint:origin withAttributedText:self.attributedHelpText];
            
            else [ZSHelpController showAtPoint:origin withText:self.helpText];
            
        }
        
    }
    
    else if(/*[[ZSHelpController sharedHelpController] callerView] &&*/ (help.hit == 1)) [ZSHelpController hide];
   
    else if(pointInside && (self == help.callerView) ) [ZSHelpController hide];
    return pointInside;
    
}

@end

@implementation ZSHelpView

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    //[ZSHelpController hide];
}

@end
#define DEFAULT_SIZE CGSizeMake(300, 300)
#define START_SIZE CGSizeMake(DEFAULT_SIZE.width/10., DEFAULT_SIZE.height/10.)
#define LABEL_FRAME CGRectMake(self.view.frame.size.width*3/10., self.view.frame.size.height*1/10., self.view.frame.size.width*6/10., self.view.frame.size.height*8/10.)
#define LABEL_WIDTH 250

#define MARGIN LABEL_WIDTH * 1/40
#define SEPARATOR LABEL_WIDTH * 1/15
#define FONT_SIZE LABEL_WIDTH * 1/20.

#define HELP_IMAGE_FRAME CGRectMake(MARGIN, MARGIN, MIN(32,self.contentLabel.frame.size.height), MIN(32,self.contentLabel.frame.size.height))

#define ARROW_FRAME CGRectMake((self.position %2 == 0) ? CGRectGetMaxX(self.contentView.frame) - ARROW_WIDTH*.8 : ARROW_WIDTH*.55, (self.position < 2) ? CGRectGetMaxY(self.contentView.frame) - ARROW_WIDTH*.55 : ARROW_WIDTH*.60, ARROW_WIDTH, ARROW_WIDTH)


@implementation ZSHelpController


+ (id)sharedHelpController
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        
        sharedInstance = [[ZSHelpController alloc] init];
    });
    return sharedInstance;
}


+(void) setForClass:(__unsafe_unretained Class)myClass
{
    [myClass jr_swizzleMethod:@selector(pointInside:withEvent:) withMethod:@selector(zshc_pointInside:withEvent:) error:nil];
    
    
    /*
     Class aClass = [myClass class];
    
    while((aClass = [aClass superclass]))
    {
        [myClass jr_swizzleMethod:@selector(touchesBegan:withEvent:) withMethod:@selector(zshc_touchesBegan:withEvent:) error:nil];
    }*/
}

+(void) set
{
    //[ZSHelpController setForClass:[UIResponder class]];
    [ZSHelpController setForClass:[UIView class]];
}

-(void) setTextColor:(UIColor *)textColor
{
    self.contentLabel.textColor = textColor;
}

-(void) setBackgroundColor:(UIColor *)backgroundColor
{
    self.contentView.backgroundColor = backgroundColor;
}

-(void) setIcon:(UIImage *)image
{
    _icon = image;
    self.helpImageView.image = self.icon;
}


#pragma mark - Display
+(void) showAtPoint:(CGPoint)point withText:(NSString *)text
{
    ZSHelpController *helpController = [ZSHelpController sharedHelpController];
    helpController.contentLabel.text = text;
    helpController.origin = point;
    [helpController show];
}

+(void) showAtPoint:(CGPoint)point withAttributedText:(NSAttributedString *)attributedText
{
    ZSHelpController *helpController = [ZSHelpController sharedHelpController];
    helpController.contentLabel.attributedText = attributedText;
    helpController.origin = point;
    [helpController show];
}


+(void) hide
{
    [[ZSHelpController sharedHelpController] dismiss:nil];
    [[ZSHelpController sharedHelpController] setCallerView:nil];
}


+(void) toggle
{
    BOOL enabled = [[ZSHelpController sharedHelpController] enabled];
    [[ZSHelpController sharedHelpController] setEnabled:!enabled];
}

+(BOOL) isVisible
{
    BOOL visible = ([[[ZSHelpController sharedHelpController] view] superview] != nil);
    return visible;
}

-(CGRect) frameInTargetView
{
    if([ZSHelpController isVisible]) return self.view.frame;

    else return CGRectZero;
}

-(id) init
{
    if(self = [super init])
    {
        self.size = DEFAULT_SIZE;
        self.position = ZSCenter;
        self.hit = 0;
    }
    
    return self;
}

#pragma elements

-(UIView *) view
{
    if(_view == nil)
    {
        ZSHelpView *view = [[ZSHelpView alloc] init];
        view.backgroundColor = [UIColor clearColor];
        view.layer.cornerRadius = 5.0;
        _view = view;
    }
    
    return _view;
}

-(UIView *) contentView
{
    if(_contentView == nil)
    {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor clearColor];
        view.layer.cornerRadius = 5.0;
        _contentView = view;
        [_contentView.layer setShadowOpacity:0.3];
        [_contentView.layer setShadowOffset:CGSizeMake(0, 4)];
    }
    
    return _contentView;
}


-(UILabel *)contentLabel
{
    if(_contentLabel == nil)
    {
        UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        contentLabel.text = nil;
        contentLabel.backgroundColor = [UIColor clearColor];
        contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
        contentLabel.numberOfLines = 0;
        contentLabel.textColor = self.textColor;
        _contentLabel = contentLabel;
    }
    
    return _contentLabel;
}

-(UIImageView *)helpImageView
{
    if(_helpImageView ==nil)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:self.icon];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.backgroundColor = [UIColor clearColor];
        _helpImageView = imageView;
    }
    
    return _helpImageView;
}

-(void) setFont:(NSString *)fontName withColor:(UIColor *)color
{
    _textColor = color;
    _font = [UIFont fontWithName:fontName  size:FONT_SIZE];
    self.contentLabel.font = _font;
    self.contentLabel.textColor = color;
    
}
#pragma private

-(void) show
{
    if([self.view superview]) return;
    
    self.position = [self autoPosition];
    [self layoutSubviews];
    [self.targetView addSubview:self.view];
    
    self.view.alpha = 0.;

    [UIView animateWithDuration:.1 delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.view.alpha = 1.;
    } completion:^(BOOL finished) {
        self.hit++;
    }];

}

-(ZSPosition) autoPosition
{
    int position = 0;
    
    if(self.origin.x < self.targetView.center.x) position++;
    
    if(self.origin.y < self.targetView.center.y) position+=2;
    
    return position;
}

-(CGRect) frame
{
    CGRect frame = CGRectZero;
    
    CGFloat width = self.contentView.frame.size.width + SEPARATOR;
    CGFloat height = self.contentView.frame.size.height + SEPARATOR;
    
    switch (self.position) {
        case ZSTopLeft:
            frame = CGRectMake(self.origin.x-width, self.origin.y-height, width, height);
            break;
        case ZSTopRight:
            frame = CGRectMake(self.origin.x, self.origin.y-height, width, height);
            break;
        case ZSBottomLeft:
            frame = CGRectMake(self.origin.x-width, self.origin.y, width, height);
            break;
        case ZSBottomRight:
            frame = CGRectMake(self.origin.x,self.origin.y,  width, height);
            break;
        case ZSCenter:
        default:
        {
            frame = CGRectMake(self.targetView.center.x - self.size.width/2.0, self.targetView.center.y - self.size.height/2.0, self.size.width, self.size.height);
        }
            break;
    }
    
    return frame;
}

-(void) layoutSubviews
{
    CGSize size = [self.contentLabel sizeThatFits:CGSizeMake(LABEL_WIDTH, MAXFLOAT)];
    CGRect frame = self.contentLabel.frame; frame.size = size; self.contentLabel.frame = frame;
    
    self.helpImageView.frame = HELP_IMAGE_FRAME;
    
    frame.origin = CGPointMake(CGRectGetMaxX(self.helpImageView.frame) + MARGIN, MARGIN); self.contentLabel.frame = frame;
    
    self.contentView.frame = CGRectMake( (self.position % 2) == 0 ? 0 : SEPARATOR, (self.position < 2) ? 0 : SEPARATOR, self.helpImageView.frame.size.width + self.contentLabel.frame.size.width + MARGIN * 3, self.contentLabel.frame.size.height + MARGIN * 2);
    
    self.view.frame = [self frame];
    
    [self.contentView addSubview:self.contentLabel];
    [self.contentView addSubview:self.helpImageView];
    [self.view addSubview:self.contentView];
    //[self.view addSubview:self.arrow];
    
}

-(void) dismiss:(id)sender
{
    if(self.view.superview)
    {
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self.view removeFromSuperview];
            //[self.arrow removeFromSuperview];
            [self.contentView removeFromSuperview];
        } completion:^(BOOL finished) {
            self.hit = 0;
            self.view = nil;
        }];
        
    }
    
    self.contentLabel.text = nil;
}

@end

@interface ZSArrow ()

@property (nonatomic) double direction;
@property (nonatomic, strong) UIColor *color;

@end

@implementation ZSArrow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.borderColor = [UIColor clearColor].CGColor;
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    
    CGPoint points[3] = { CGPointMake(0, self.frame.size.height), CGPointMake(self.frame.size.width/2., 0), CGPointMake(self.frame.size.width, self.frame.size.height) };
    
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, points[0].x, points[0].y);
    CGContextAddLineToPoint(ctx, points[1].x, points[1].y);
    CGContextAddLineToPoint(ctx, points[2].x, points[2].y);
    CGContextAddLineToPoint(ctx, points[0].x, points[0].y);
    CGContextSetFillColorWithColor(ctx, self.color.CGColor);
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
    
    self.transform = CGAffineTransformMakeRotation(self.direction);
    
    
}

+(ZSArrow *) arrowWithFrame:(CGRect)frame direction:(double)direction color:(UIColor *)color
{
    ZSArrow *arrow = [[ZSArrow alloc] initWithFrame:frame];
    arrow.direction = direction;
    arrow.color = color;
    return arrow;
}
@end



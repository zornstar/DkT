//
//  ZSHelpController.m
//  DkTp
//
//  Created by Matthew Zorn on 6/29/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "ZSHelpController.h"
#import <objc/runtime.h>
#import "JRSwizzle.h"
#import <QuartzCore/QuartzCore.h>
#import "ZSArrow.h"


NSString *const kZSHelpTextKey = @"kZSHelpTextKey";
NSString *const kZSAttributedHelpTextKey = @"kZSAttributedHelpTextKey";


@interface ZSHelpController ()

@property (nonatomic, strong) UIView *callerView;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIImageView *helpImageView;
@property (nonatomic, strong) ZSArrow *arrow;
@property (nonatomic, strong) UIFont *font;

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
    NSLog(@"%@",[self class]);
    
    BOOL pointInside = [self zshc_pointInside:point withEvent:event];
    
    if(pointInside && [[ZSHelpController sharedHelpController] enabled])
    {
        if(self.attributedHelpText.length > 0)
        {
            
            UIView *targetView = [UIApplication sharedApplication].keyWindow;
            
            [[ZSHelpController sharedHelpController] setTargetView:targetView];
            [[ZSHelpController sharedHelpController] setCallerView:self];
            
            CGPoint origin = [targetView convertPoint:point fromView:self];
            [ZSHelpController showAtPoint:origin withAttributedText:self.attributedHelpText];

        }
        
        else if (self.helpText.length > 0)
        {
            UIView *targetView = [UIApplication sharedApplication].keyWindow;
            
            [[ZSHelpController sharedHelpController] setTargetView:targetView];
            [[ZSHelpController sharedHelpController] setCallerView:self];
            
            CGPoint origin = [targetView convertPoint:point fromView:self];
            [ZSHelpController showAtPoint:origin withText:self.helpText];
        }
        
    }
    
    else if([[ZSHelpController sharedHelpController] callerView]) [ZSHelpController hide];
    
    return pointInside;
    
}

@end

@implementation ZSHelpView

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [ZSHelpController hide];
}

@end
#define DEFAULT_SIZE CGSizeMake(300, 300)
#define START_SIZE CGSizeMake(DEFAULT_SIZE.width/10., DEFAULT_SIZE.height/10.)
#define LABEL_FRAME CGRectMake(self.view.frame.size.width*3/10., self.view.frame.size.height*1/10., self.view.frame.size.width*6/10., self.view.frame.size.height*8/10.)
#define LABEL_WIDTH 250

#define MARGIN LABEL_WIDTH * 1/40
#define ARROW_WIDTH LABEL_WIDTH * 1/20
#define FONT_SIZE LABEL_WIDTH * 1/20.

#define HELP_IMAGE_FRAME CGRectMake(MARGIN, MARGIN, MIN(32,self.contentLabel.frame.size.height), MIN(32,self.contentLabel.frame.size.height))

#define ARROW_FRAME CGRectMake((self.position %2 == 0) ? CGRectGetMaxX(self.contentView.frame) - ARROW_WIDTH*.45 : ARROW_WIDTH*.55, (self.position < 2) ? CGRectGetMaxY(self.contentView.frame) - ARROW_WIDTH*.55 : ARROW_WIDTH*.45, ARROW_WIDTH, ARROW_WIDTH)


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

-(id) init
{
    if(self = [super init])
    {
        self.size = DEFAULT_SIZE;
        self.position = ZSCenter;
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
    self.position = [self autoPosition];
   
    [self layoutSubviews];
    [self.targetView addSubview:self.view];

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
    
    CGFloat width = self.contentView.frame.size.width + ARROW_WIDTH;
    CGFloat height = self.contentView.frame.size.height + ARROW_WIDTH;
    
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
    
    self.contentView.frame = CGRectMake( (self.position % 2) == 0 ? 0 : ARROW_WIDTH, (self.position < 2) ? 0 : ARROW_WIDTH, self.helpImageView.frame.size.width + self.contentLabel.frame.size.width + MARGIN * 3, self.contentLabel.frame.size.height + MARGIN * 2);
    
    self.arrow = [ZSArrow arrowWithFrame:ARROW_FRAME direction:M_PI+M_PI_4+(self.position-1)*M_PI_4
                                   color:self.contentView.backgroundColor];
    self.view.frame = [self frame];
    
    [self.contentView addSubview:self.contentLabel];
    [self.contentView addSubview:self.helpImageView];
    [self.view addSubview:self.contentView];
    [self.view addSubview:self.arrow];
}

-(void) dismiss:(id)sender
{
    if(self.view.superview)
    {
        [self.view removeFromSuperview];
        [self.arrow removeFromSuperview];
        [self.contentView removeFromSuperview];
    }
    
    self.contentLabel.text = nil;
}
@end


//
//  Created by Matthew Zorn on 6/29/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {ZSPopoverDirectionAny, ZSPopoverArrowDirectionUp, ZSPopoverArrowDirectionLeft, ZSPopoverArrowDirectionRight, ZSPopoverArrowDirectionDown, ZSPopoverArrowDirectionNone} ZSPopoverArrowDirection;
typedef enum {ZSTopLeft, ZSTopRight, ZSBottomLeft, ZSBottomRight, ZSCenter} ZSPosition;

//add completion block
//add delegate

@interface ZSHelpController : NSObject

@property (nonatomic) BOOL enabled;
@property (nonatomic) CGPoint origin;

@property (nonatomic, strong) NSArray *popupImages;
@property (nonatomic, weak) UIView *targetView;
@property (nonatomic, weak) UIView *callerView;
@property (nonatomic) ZSPopoverArrowDirection arrowDirection;
@property (nonatomic) ZSPosition position;

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *secondaryBackgroundColor;
@property (nonatomic, strong) UIColor *textColor;

@property (nonatomic, strong) UIImage *icon;
@property (nonatomic) CGSize size;

#pragma mark - class methods 
+(id) sharedHelpController;

+(void) showAtPoint:(CGPoint)point withText:(NSString *)text;
+(void) showAtPoint:(CGPoint)point withAttributedText:(NSAttributedString *)attributedText;

+(void) hide;
+(void) toggle;

+(void) set;
+(void) setForClass:(Class)myClass;
+(BOOL)isVisible;
#pragma mark - instance methods 
-(void) setIcon:(UIImage *)image;
-(void) setFont:(NSString *)fontName withColor:(UIColor *)color;
-(CGRect) frameInTargetView;

@end

@interface UIView (Help)

@property (nonatomic, copy) NSAttributedString *attributedHelpText;
@property (nonatomic, copy) NSString *helpText;

@end

@interface ZSHelpView : UIView

@end

@interface ZSArrow : UIView

+(ZSArrow *) arrowWithFrame:(CGRect)frame direction:(double)direction color:(UIColor *)color;

@end
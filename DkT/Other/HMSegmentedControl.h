/*
  HMSegmentedControl.h
    HMSegmentedControl
 Copyright (c) 2012 Hesham Abd-Elmegid (http://www.hesh.am)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */

#import <UIKit/UIKit.h>

typedef void (^IndexChangeBlock)(NSInteger index);

typedef enum {
    HMSegmentedControlTypeText,
    HMSegmentedControlTypeImages,
    HMSegmentedControlTypeCustom, //mz modification
} HMSegmentedControlType;

typedef enum {
    HMSegmentedControlSelectionStyleTextWidthStrip, // Indicator width will only be as big as the text width
    HMSegmentedControlSelectionStyleFullWidthStrip, // Indicator width will fill the whole segment
    HMSegmentedControlSelectionStyleBox
} HMSegmentedControlSelectionStyle;

typedef enum {
    HMSegmentedControlSelectionLocationUp,
    HMSegmentedControlSelectionLocationDown
} HMSegmentedControlSelectionLocation;

enum {
    HMSegmentedControlNoSegment = -1   // segment index for no selected segment
};

@interface HMSegmentedControl : UIControl

@property (nonatomic, strong) NSArray *sectionTitles;
@property (nonatomic, strong) NSArray *sectionImages;
@property (nonatomic, strong) NSArray *sectionSelectedImages;

@property (nonatomic, copy) IndexChangeBlock indexChangeBlock; // you can also use addTarget:action:forControlEvents:

@property (nonatomic, strong) UIFont *font; // default is [UIFont fontWithName:@"STHeitiSC-Light" size:18.0f]
@property (nonatomic, strong) UIColor *textColor; // default is [UIColor blackColor]
@property (nonatomic, strong) UIColor *selectedTextColor; // default is [UIColor blackColor]
@property (nonatomic, strong) UIColor *backgroundColor; // default is [UIColor whiteColor]
@property (nonatomic, strong) UIColor *selectionIndicatorColor; // default is R:52, G:181, B:229
@property (nonatomic, assign) HMSegmentedControlSelectionStyle selectionStyle; // Default is HMSegmentedControlSelectionStyleTextWidthStrip
@property (nonatomic, assign) HMSegmentedControlSelectionLocation selectionLocation; // Default is HMSegmentedControlSelectionLocationUp
@property (nonatomic, assign) HMSegmentedControlType type;

@property (nonatomic, assign) NSInteger selectedSegmentIndex;
@property (nonatomic, readwrite) CGFloat height; // default is 32.0
@property (nonatomic, readwrite) CGFloat selectionIndicatorHeight; // default is 5.0
@property (nonatomic, readwrite) UIEdgeInsets segmentEdgeInset; // default is UIEdgeInsetsMake(0, 5, 0, 5)

//mz modification
@property (nonatomic, strong) CALayer *selectionIndicatorStripLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorBoxLayer;
@property (nonatomic, readwrite) CGFloat segmentWidth;


- (id)initWithSectionTitles:(NSArray *)sectiontitles;
- (id)initWithSectionImages:(NSArray *)sectionImages sectionSelectedImages:(NSArray *)sectionSelectedImages;
- (void)setSelectedSegmentIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)setIndexChangeBlock:(IndexChangeBlock)indexChangeBlock;

@end
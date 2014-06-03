
//
//  Created by Matthew Zorn on 8/20/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTPodTabBarController.h"
#import "DkTSearchViewController.h"
#import "DkTBookmarkViewController.h"
#import "UIImage+Utilities.h"
#import "DkTDocumentsViewController.h"
#import "DkTSegmentedController.h"

@interface DkTPodTabBarController ()

@end

@implementation DkTPodTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITabBarItem *searchItem = [[UITabBarItem alloc] initWithTitle:@"Search" image:nil tag:0];
    [searchItem setFinishedSelectedImage:[kSearchImage imageWithColor:[UIColor inactiveColor]] withFinishedUnselectedImage:[kSearchImage imageWithColor:[UIColor darkerTextColor]]];
    
    UITabBarItem *bookmarkItem = [[UITabBarItem alloc] initWithTitle:@"Bookmarks" image:nil tag:0];
    [bookmarkItem setFinishedSelectedImage:[kBookmarkImage imageWithColor:[UIColor inactiveColor]] withFinishedUnselectedImage:[kBookmarkImage imageWithColor:[UIColor darkerTextColor]]];
    
    UITabBarItem *documentsItem = [[UITabBarItem alloc] initWithTitle:@"Documents" image:nil tag:0];
    [documentsItem setFinishedSelectedImage:[kDocumentsImage imageWithColor:[UIColor inactiveColor]] withFinishedUnselectedImage:[kDocumentsImage imageWithColor:[UIColor darkerTextColor]]];
    
    
    DkTSegmentedController *findController = [[DkTSegmentedController alloc] init];
    findController.tabBarItem = searchItem;
    
    
    DkTBookmarkViewController *bookmarkViewController = [[DkTBookmarkViewController alloc] init];
    bookmarkViewController.tabBarItem = bookmarkItem;
    
    DkTDocumentsViewController *documentsViewController =[[DkTDocumentsViewController alloc] init];
    documentsViewController.tabBarItem = documentsItem;
    
    self.tabBar.tintColor = [UIColor activeColor];
    [self.tabBar addGestureRecognizer:[self longPress]];
    IOS7(self.tabBar.translucent = NO;, );
    self.viewControllers = @[findController, bookmarkViewController, documentsViewController];
    
    
}

-(void) viewDidAppear:(BOOL)animated
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        [self setSelectedIndex:1];
        [self setSelectedIndex:0];
    });
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL) shouldAutorotate
{
    return NO;
}

-(UILongPressGestureRecognizer *) longPress
{
    return [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
}
-(void) handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if(sender.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [sender locationInView:self.tabBar];
        
        if((point.x >= 324/3.) && (point.x <= 324/3.*2))
        {
            DkTBookmarkViewController *bvc = [self.viewControllers objectAtIndex:1];
            [bvc updateAllBookmarks];
        }
        
    }
    
}




@end

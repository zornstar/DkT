
//
//  Created by Matthew Zorn on 7/14/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTSpecificDocumentViewController.h"
#import "UIImage+Utilities.h"
#import "DkTDocketEntry.h"

@interface DkTSpecificDocumentViewController ()

@property (nonatomic) DkTDocumentViewControllerType type;
@end

@implementation DkTSpecificDocumentViewController

-(id) init
{
    return [self initWithType:DkTCustomDocumentViewControllerType];
}

- (id)initWithType:(DkTDocumentViewControllerType)type
{
    if(self = [super init])
    {
        self.type = type;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor inactiveColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, PAD_OR_POD(400,225), MAXFLOAT)];
    label.numberOfLines = 0;
    label.textColor = [UIColor activeColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.backgroundColor = [UIColor clearColor];

    UIImageView *img;
    
    if(self.type == DkTSealedDocumentViewControllerType)
    {
        
        label.text = [NSString stringWithFormat:@"You do not have permission\nto view this document.\n\n(Entry %@ may be under seal)", self.entry.entryString];
        img = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"lock"] imageWithColor:[UIColor activeColor]] ];

    }
    
    if(self.type == DkTNoDocumentViewControllerType)
    {
        label.text = @"Touch a docket entry\nto load a document.";
        img = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"backarrow"] imageWithColor:[UIColor activeColor]]];
    }
    
    if(self.type == DkTErrorDocumentViewControllerType)
    {
        
        label.text = [NSString stringWithFormat:@"Error loading document %@.", self.entry.entryString];
        img = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"warning"] imageWithColor:[UIColor activeColor]]];
        
    }
    
    [label sizeToFit];
    label.center = CGPointMake(self.view.center.x+16, self.view.center.y);
    img.frame = CGRectMake(CGRectGetMinX(label.frame)-50, self.view.center.y - 16, 32, 32);
    img.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:label]; [self.view addSubview:img];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

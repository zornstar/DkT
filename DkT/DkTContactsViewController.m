//
//  DkTContactsViewController.m
//  DkTp
//
//  Created by Matthew Zorn on 7/9/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTContactsViewController.h"
#import <AddressBook/AddressBook.h>

@interface DkTContactsViewController ()

@property (nonatomic, strong) NSArray *contacts;

@end

@implementation DkTContactsViewController

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
	// Do any additional setup after loading the view.
}

-(NSArray *) contacts
{
    if(_contacts == nil)
    {
    
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  RECAPShareViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 6/28/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTShareViewController.h"
#import <Social/Social.h>
#import <QuartzCore/QuartzCore.h>
#import "PACERClient.h"
#import <MessageUI/MessageUI.h>


@interface DkTShareViewController ()

@property (nonatomic, strong) NSArray *icons;
@property (nonatomic, strong) NSArray *names;

@end

@implementation DkTShareViewController

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UITableView *) tableView
{
    if(_tableView == nil)
    {
        CGFloat x = CGRectGetMaxX(self.cell.frame), y = CGRectGetMaxY(self.cell.frame);
        
        CGRect frame = CGRectMake(x,y, self.containerView.frame.size.width - x, self.containerView.frame.size.height - y);
        _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        _tableView.layer.cornerRadius = 5.0;
        _tableView.delegate = self;
        _tableView.scrollEnabled = NO;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
    }
    
    return _tableView;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[PACERClient sharedClient] networkReachabilityStatus] > 0) // connected to the internet
    {
        UIViewController *vc;
        
        if(indexPath.row == 0)
        {
            vc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [(SLComposeViewController *)vc setInitialText:[NSString stringWithFormat:@"Check out %@ on the App Store.", kAppName]];
            [(SLComposeViewController *)vc addURL:[NSURL URLWithString:kAppStoreURL]];
            [self presentViewController:vc animated:YES completion:nil];
        }
        
        if(indexPath.row == 1)
        {
            vc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [(SLComposeViewController *)vc setInitialText:[NSString stringWithFormat:@"Check out %@ on the App Store.", kAppName]];
            [(SLComposeViewController *)vc addURL:[NSURL URLWithString:kAppStoreURL]];
            [self presentViewController:vc animated:YES completion:nil];
        }
        
        if(indexPath.row == 2)
        {
            if([MFMailComposeViewController canSendMail])
            {
                MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
                [mailVC setSubject:@"Check out %@ on the App Store"];
                [mailVC setMessageBody:kAppStoreURL isHTML:NO];
                
                [self presentViewController:mailVC animated:YES completion:^{
                    
                }];
            }
        }
    }
    
    else
    {
        
    }
    UIViewController *vc;
    
    
}

@end

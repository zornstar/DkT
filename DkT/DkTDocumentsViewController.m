//
//  RECAPDocumentsViewController.m
//  RECAPp
//
//  Created by Matthew Zorn on 5/21/13.
//  Copyright (c) 2013 Matthew Zorn. All rights reserved.
//

#import "DkTDocumentsViewController.h"
#import "DkTDocumentManager.h"
#import "DkTDetailViewController.h"
#import "ReaderViewController.h"
#import "UIImage+Utilities.h"
#import "UIView+Utilities.h"
#import <QuartzCore/QuartzCore.h>

#define TABLE_HEIGHT  _tableView.rowHeight * MAX(self.dockets.count, 1);

@interface DkTDocumentsViewController ()
@property (nonatomic, strong) NSArray *dockets;
@end

@implementation DkTDocumentsViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        [DkTDocumentManager setDelegate:self];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = kActiveColor;
    self.dockets = [self getSavedDockets];
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSArray *) getSavedDockets
{
    NSMutableArray * items = [NSMutableArray array];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSArray *dockets = [DkTDocumentManager dockets];
    
    for(NSString *docketName in dockets)
    {
        NSString *aFile;
        NSString *docketPath = [DkTDocumentManager pathToDocket:docketName];
        
        NSLog(@"%@", docketPath);
        
        NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:docketPath];
        NSMutableArray *files = [NSMutableArray array];
            
        while ((aFile = [enumerator nextObject] )) {
                
            if ([aFile hasSuffix:@".pdf"]) {
                    
                [files addObject:[aFile lastPathComponent]];
                    
            }
                
        }
            
            NSMutableDictionary *docketDictionary = [@{@"path":docketPath, @"name":[docketName lastPathComponent], @"files":files, @"collapsed":[NSNumber numberWithBool:YES]} mutableCopy];
            [items addObject:docketDictionary];
        }
    
    return items;
}

-(UITableView *) tableView
{
    if(_tableView == nil)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        
        _tableView.rowHeight = 60;
        
        CGRect frame;
        frame.size.height = self.view.frame.size.height;
        frame.size.width = self.view.frame.size.width*.85;
        frame.origin = CGPointMake((self.view.frame.size.width -frame.size.width)/2.0,(self.view.frame.size.width -frame.size.width)/2.0);
        _tableView.frame = frame;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.scrollEnabled = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.separatorColor = kDarkTextColor;
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = kActiveColor;
        [_tableView setBackgroundView:backgroundView];
        
        _tableView.layer.cornerRadius = 5.0;
    }
    
    return _tableView;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dockets.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 5;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.dockets.count == 0) return 1;
    
    NSDictionary *sectionDictionary = [self.dockets objectAtIndex:section];
    
    NSInteger fileCount = [[sectionDictionary objectForKey:@"files"] count];
    
    return [[sectionDictionary objectForKey:@"collapsed"] boolValue] ? 1 : fileCount + 1;
    
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row > 0) return 5;
    
    else return 0;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    UITableViewCell *cell;
    
    if(self.dockets.count == 0)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        cell.textLabel.text = @"You currently have no saved dockets.";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:kLightFont size:16];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = kActiveColor;
        cell.contentView.backgroundColor = kInactiveColor;
        
        return cell;
    }
    
    NSMutableDictionary *sectionDictionary = [self.dockets objectAtIndex:indexPath.section];
    
    
    if(indexPath.row == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TopCell"];
        
        if(cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TopCell"];
            
            cell.textLabel.font = [UIFont fontWithName:kMainFont size:16];
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.textColor = kDarkTextColor;
            cell.detailTextLabel.textColor = kActiveColorLight;
            cell.imageView.image = [kFolderImage imageWithColor:kDarkTextColor];
            cell.layer.cornerRadius = 4.0;
        }
        
        BOOL collapsed = [[sectionDictionary objectForKey:@"collapsed"] boolValue];
        
        
        cell.contentView.backgroundColor = collapsed ? kInactiveColor : kInactiveColorDark;
        cell.textLabel.text = [sectionDictionary objectForKey:@"name"];
        cell.backgroundColor = [UIColor clearColor];
        cell.clipsToBounds = YES;
        
        if(collapsed && (indexPath.section == self.dockets.count-1))
        {
            [cell.contentView roundCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight)];
        }

    }
    
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"BodyCell"];
        
        if(cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"BodyCell"];
            cell.textLabel.font = [UIFont fontWithName:kLightFont size:14];
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.textLabel.textColor = kActiveColor;
            cell.detailTextLabel.textColor = kActiveColorLight;
            cell.detailTextLabel.backgroundColor = [UIColor clearColor];
            cell.contentView.backgroundColor = kInactiveColor;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.imageView.image = [kDocumentIcon imageWithColor:kActiveColor];
            cell.imageView.transform = CGAffineTransformMakeScale(.5, .5);
            cell.layer.cornerRadius = 4.0;
        }
        
        
        cell.textLabel.text = [[sectionDictionary objectForKey:@"files"] objectAtIndex:indexPath.row - 1];
        
        
    }
    
    return cell;
    
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    return view;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *sectionDictionary = [self.dockets objectAtIndex:indexPath.section];
    
    if(indexPath.row == 0)
    {
        BOOL collapsed = [[sectionDictionary objectForKey:@"collapsed"] boolValue];
        
        NSMutableArray *paths = [NSMutableArray array];
            
        
        [sectionDictionary setObject:[NSNumber numberWithBool:!collapsed] forKey:@"collapsed"];
            
        NSInteger fileCount = [[sectionDictionary objectForKey:@"files"] count];
            
        for(int i = 1; i <= fileCount; ++i)
        {
            [paths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        }
         
        
        CGRect frame = self.tableView.frame;
        frame.size.height += (collapsed*2 - 1) * fileCount * self.tableView.rowHeight;
        
        
        [CATransaction begin];
        
         self.tableView.frame = frame;
        [tableView beginUpdates];
            
            
            if(collapsed)
                [tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
        
            else
                [tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
        
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
         
        
        
            
            [tableView endUpdates];
            
           [CATransaction commit];
    }
    
    else
    {
        
        NSString *fileName = [[sectionDictionary objectForKey:@"files"] objectAtIndex:indexPath.row - 1];
        NSString *path = [[sectionDictionary objectForKey:@"path"] stringByAppendingPathComponent:fileName];
        ReaderDocument *document = [[ReaderDocument alloc] initWithFilePath:path password:nil];
        ReaderViewController *documentViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
        
        DkTDetailViewController *detailViewController = [[DkTDetailViewController alloc] init];
        [detailViewController addChildViewController:documentViewController];
        [detailViewController.view addSubview:documentViewController.view];
        [detailViewController setDocketEntry:nil];
        detailViewController.title = fileName;
        detailViewController.isLocal = YES;
        [detailViewController setFilePath:path];
        
        UINavigationController *navCtr = [[UINavigationController alloc] initWithRootViewController:detailViewController];
        
        [self presentViewController:navCtr animated:YES completion:^{
            
        }];
    }
}

-(void) didSaveDocumentAtPath:(NSString *)path
{
    dispatch_async(dispatch_queue_create("reload dockets", 0), ^{
        [self getSavedDockets];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.tableView reloadData];
        });
    });
}

@end

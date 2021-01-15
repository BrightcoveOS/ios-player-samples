//
//  ListViewController.m
//  BasicPulsetvOSPlayer
//
//  Created by Carlos Ceja on 2/18/20.
//  Copyright © 2020 Carlos Ceja. All rights reserved.
//

#import <AppTrackingTransparency/AppTrackingTransparency.h>

#import "ListViewController.h"

#import "BCOVPulseVideoItem.h"
#import "ViewController.h"


@interface ListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray <BCOVPulseVideoItem *> *videoItems;

@end


@implementation ListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (@available(tvOS 14, *))
    {
        __weak typeof(self) weakSelf = self;
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                // Tracking authorization completed. Start loading ads here.
                [strongSelf videoLibrary];
            });
        }];
    }
    else
    {
        [self videoLibrary];
    }
}

#pragma mark Misc

- (NSArray<NSDictionary *> *)jsonVideoObjects
{
    NSError *jsonError;
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"Library" ofType:@"json"];
    NSArray<NSDictionary *> *jsonObjects = [NSJSONSerialization JSONObjectWithData:[[NSData alloc] initWithContentsOfFile:path] options:0 error:&jsonError];
    
    assert(jsonError == nil);
    return jsonObjects;
}

- (void)videoLibrary
{
    if (!self.videoItems)
    {
        // Parse and add each video in the JSON array to our video library
        NSMutableArray *videos = [NSMutableArray array];
        
        for (NSDictionary *jsonObject in [self jsonVideoObjects])
        {
            [videos addObject:[BCOVPulseVideoItem initWithDictionary:jsonObject]];
        }
        
        self.videoItems = [NSArray arrayWithArray:videos];
    }

    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.videoItems.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Basic Pulse tvOS Player";
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    ((UITableViewHeaderFooterView *) view).contentView.backgroundColor = UIColor.darkGrayColor;
    ((UITableViewHeaderFooterView *) view).textLabel.textColor = UIColor.whiteColor;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell" forIndexPath:indexPath];
    
    BCOVPulseVideoItem *item = self.videoItems[indexPath.item];
    
    cell.textLabel.text = item.title ?: @"";
    cell.textLabel.textColor = UIColor.blackColor;
    
    NSString *subtitle = item.category ?: @"";
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", subtitle, [item.tags componentsJoinedByString:@", "] ?: @""];
    cell.detailTextLabel.textColor = UIColor.grayColor;
    
    return cell;
}

#pragma mark Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ViewControllerSegue"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        BCOVPulseVideoItem *videoItem = self.videoItems[indexPath.item];

        ViewController *destinationVC = segue.destinationViewController;
        destinationVC.videoItem = videoItem;
    }
}

@end

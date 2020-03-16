//
//  ListViewController.m
//  BasicPulsetvOSPlayer
//
//  Created by Carlos Ceja on 2/18/20.
//  Copyright © 2020 Carlos Ceja. All rights reserved.
//

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
    
    [self videoLibrary];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell" forIndexPath:indexPath];
    
    BCOVPulseVideoItem *item = self.videoItems[indexPath.item];
    
    cell.textLabel.text = item.title ?: @"";
    
    NSString *subtitle = item.category ?: @"";
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", subtitle, [item.tags componentsJoinedByString:@", "] ?: @""];
    
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

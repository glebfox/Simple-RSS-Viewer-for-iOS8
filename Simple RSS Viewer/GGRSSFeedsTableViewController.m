//
//  GGRSSFeedsTableViewController.m
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 25.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSFeedsTableViewController.h"
#import "GGRSSFeedsCollection.h"
#import "GGRSSDimensionsProvider.h"
#import "GGRSSMasterViewController.h"

NSString *observerKey = @"feeds";

@interface GGRSSFeedsTableViewController ()

@end

@implementation GGRSSFeedsTableViewController

@synthesize url;

- (void)viewWillDisappear:(BOOL)animated
{
    // Если форма не отображается, то ей и не обязательно знать об изменениях в списке фидов
    [[GGRSSFeedsCollection sharedInstance] removeObserver:self forKeyPath:observerKey];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Подписываемся на изменения в списке фидов
    [[GGRSSFeedsCollection sharedInstance] addObserver:self forKeyPath:observerKey options:NSKeyValueObservingOptionNew context:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.feedsToDisplay.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentider = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentider forIndexPath:indexPath];
    
    if (cell != nil) {
        GGRSSFeedInfo *info = self.feedsToDisplay[indexPath.row];
        
        // Заголовок будет хранить название фида
        cell.textLabel.font = [UIFont boldSystemFontOfSize:[[GGRSSDimensionsProvider sharedInstance] dimensionByName:@"FeedsTableView_TitleSize"]];
        cell.textLabel.text = info.title;
    
        // Подзаголовок будет хранить адрес фида
        cell.detailTextLabel.font = [UIFont systemFontOfSize:[[GGRSSDimensionsProvider sharedInstance] dimensionByName:@"FeedsTableView_SubtitleSize"]];
        cell.detailTextLabel.text = [info.url absoluteString];
        
        if ([[[GGRSSFeedsCollection sharedInstance] lastUsedUrl] isEqual:info.url]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Удаляем выбранную строку с формы и из ресурсов
        GGRSSFeedInfo *info = self.feedsToDisplay[indexPath.row];
        [[GGRSSFeedsCollection sharedInstance] deleteFeedWithTitle:info.title];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Если список фидов был изменен, то обновляем таблицу
    if ([keyPath isEqualToString:observerKey]) {
        self.feedsToDisplay = [[GGRSSFeedsCollection sharedInstance] allFeeds];
        [self.tableView reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController class] == [GGRSSMasterViewController class]) {
        // Если переход вызван не нажатием на ячейку таблицы
        if ([sender class] != [UITableViewCell class]) {
            // То выозвращаем пустой url
            self.url = nil;
            return;
        }
        
        // В остальныйх случая считываем адресс фида с ячейки
        UITableViewCell *cell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        GGRSSFeedInfo *info = self.feedsToDisplay[indexPath.row];
        self.url = info.url;
    }
}

- (IBAction)unwindToFeeds:(UIStoryboardSegue *)segue
{
    [[GGRSSFeedsCollection sharedInstance] addObserver:self forKeyPath:observerKey options:NSKeyValueObservingOptionNew context:nil];
}

@end

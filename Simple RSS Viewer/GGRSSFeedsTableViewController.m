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

@interface GGRSSFeedsTableViewController ()

@property NSArray *feedsInfo;   // Список фидов для отображения

@end

@implementation GGRSSFeedsTableViewController

@synthesize url;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.feedsInfo = [[GGRSSFeedsCollection sharedInstance] allFeeds];
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
    return self.feedsInfo.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentider = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentider forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentider];
    }
    
    // Заголовок будет хранить название фида
    cell.textLabel.font = [UIFont boldSystemFontOfSize:[[GGRSSDimensionsProvider sharedInstance] dimensionByName:@"TableView_TitleSize"]];
    cell.textLabel.text = self.feedsInfo[indexPath.row][0];
    
    // Подзаголовок будет хранить адрес фида
    cell.detailTextLabel.font = [UIFont systemFontOfSize:[[GGRSSDimensionsProvider sharedInstance] dimensionByName:@"TableView_SubtitleSize"]];
    cell.detailTextLabel.text = self.feedsInfo[indexPath.row][1];
    
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
        [[GGRSSFeedsCollection sharedInstance] deleteFeedAtIndex:indexPath.row];
        self.feedsInfo = [[GGRSSFeedsCollection sharedInstance] allFeeds];
        [tableView reloadData];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
        self.url = self.feedsInfo[indexPath.row][1];
//        self.url = [NSURL URLWithString:cell.detailTextLabel.text];
    }
}

- (IBAction)unwindToFeeds:(UIStoryboardSegue *)segue
{

}

@end

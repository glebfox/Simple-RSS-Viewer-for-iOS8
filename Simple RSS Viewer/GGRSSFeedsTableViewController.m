//
//  GGRSSFeedsTableViewController.m
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 25.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSFeedsTableViewController.h"
#import "GGRSSMasterViewController.h"
#import "GGRSSFeedsCollection.h"

@interface GGRSSFeedsTableViewController ()

@end

@implementation GGRSSFeedsTableViewController

@synthesize url;

#pragma mark - init

- (id)init {
    if ((self = [super init])) {
        [self ggrssFeedsTableViewInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self ggrssFeedsTableViewInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        [self ggrssFeedsTableViewInit];
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    if ((self = [super initWithStyle:style])) {
        [self ggrssFeedsTableViewInit];
    }
    return self;
}

- (void)ggrssFeedsTableViewInit {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedsDidChanged:) name:GGRSSFeedsCollectionChangedNotification object:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        cell.textLabel.text = info.title;
    
        // Подзаголовок будет хранить адрес фида
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

#pragma mark - GGRSSFeedsCollectionNotification

- (void)feedsDidChanged:(NSNotification *)notification {
    self.feedsToDisplay = [[GGRSSFeedsCollection sharedInstance] allFeeds];
    [self.tableView reloadData];
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
    
}

@end

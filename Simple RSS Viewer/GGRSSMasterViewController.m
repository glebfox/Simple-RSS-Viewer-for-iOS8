//
//  GGRSSTitlesViewController.m
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 22.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSMasterViewController.h"
#import "GGRSSDetailViewController.h"
#import "GGRSSAddFeedViewController.h"
#import "GGRSSFeedsTableViewController.h"
#import "GGRSSFeedsCollection.h"
#import "GGRSSDimensionsProvider.h"
#import "GGRSSFeedUrlSource.h"
#import "MWFeedParser.h"
#import "NSString+HTML.h"

@interface GGRSSMasterViewController ()

@property (strong, nonatomic) MWFeedParser *feedParser;
@property (strong, nonatomic) NSMutableArray *parsedItems;
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (strong, nonatomic) NSArray *itemsToDisplay;
@property GGRSSFeedsCollection *feeds;
@property GGRSSDimensionsProvider *dimensionsProvider;

@end

@implementation GGRSSMasterViewController

#pragma mark - View lifecycle

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.clearsSelectionOnViewWillAppear) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    self.formatter = [NSDateFormatter new];
    [self.formatter setDateStyle:NSDateFormatterShortStyle];
    [self.formatter setTimeStyle:NSDateFormatterShortStyle];
    self.parsedItems = [NSMutableArray new];
    self.itemsToDisplay = [NSArray new];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    self.dimensionsProvider = [GGRSSDimensionsProvider sharedInstance];
    self.feeds = [GGRSSFeedsCollection sharedInstance];
    
    NSURL *feedURL = [self.feeds lastUsedUrl];
    //    [NSURL URLWithString:@"http://images.apple.com/main/rss/hotnews/hotnews.rss"];
    //    NSURL *feedURL = [NSURL URLWithString:@"http://techcrunch.com/feed/"];
    [self setParserWithUrl:feedURL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Parsing

- (void)setParserWithUrl:(NSURL *)url
{
    self.title = NSLocalizedString (@"MasterViewTitle_Loading", nil);
    [self.spinner startAnimating];
    self.tableView.hidden = YES;
    if (self.feedParser != nil) {
        [self.feedParser stopParsing];
        self.feedParser = nil;
    }
    
    if (url != nil) {
        self.feedParser = [[MWFeedParser alloc] initWithFeedURL:url];
        self.feedParser.delegate = self;
        self.feedParser.feedParseType = ParseTypeFull; // Parse feed info and all items
        self.feedParser.connectionType = ConnectionTypeAsynchronously;
        [self.parsedItems removeAllObjects];
        [self.feedParser parse];
    }
}

- (void)refresh
{
    self.title = NSLocalizedString (@"MasterViewTitle_Refreshing", nil);
    [self.parsedItems removeAllObjects];
    [self.feedParser stopParsing];
    [self.feedParser parse];
    //self.tableView.userInteractionEnabled = NO;
    //    self.tableView.alpha = 0.3;
}

- (void)updateTableWithParsedItems
{
    self.itemsToDisplay = [self.parsedItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]]];
    //self.tableView.userInteractionEnabled = YES;
    //    self.tableView.alpha = 1;
    [self.tableView reloadData];
    self.tableView.hidden = NO;
    [self.refreshControl endRefreshing];
    [self.spinner stopAnimating];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

#pragma mark - MWFeedParserDelegate

- (void)feedParserDidStart:(MWFeedParser *)parser
{
//    NSLog(@"Started Parsing: %@", parser.url);
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info
{
//    NSLog(@"Parsed Feed Info: “%@”", info.title);
    self.title = info.title;
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{
//    NSLog(@"Parsed Feed Item: “%@”", item.title);
    if (item) [self.parsedItems addObject:item];
}

- (void)feedParserDidFinish:(MWFeedParser *)parser
{
//    NSLog(@"Finished Parsing%@", (parser.stopped ? @" (Stopped)" : @""));
    [self.feeds addFeedWithTitle:self.title absoluteUrlString:[self.feedParser.url absoluteString]];
    [self updateTableWithParsedItems];
}

- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error
{
//    NSLog(@"Finished Parsing With Error: %@", error);
//    if (self.parsedItems.count == 0) {
//        self.title = @"Failed"; // Show failed message in title
//    } else {
        // Failed but some items parsed, so show and inform of error
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString (@"AlertViewParsingIncomplete_Title", nil)
                                                        message:NSLocalizedString (@"AlertViewParsingIncomplete_Message", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString (@"AlertViewParsingIncomplete_CancelButtonTitle", nil)
                                              otherButtonTitles:nil];
        if (self.parsedItems.count > 0)
            [self.parsedItems removeAllObjects];
        [alert show];
//    }
    self.title = NSLocalizedString (@"MasterViewTitle_Failed", nil);
    [self updateTableWithParsedItems];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.itemsToDisplay.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentider = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentider forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentider];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell...
    MWFeedItem *item = [self.itemsToDisplay objectAtIndex:indexPath.row];
    if (item) {
        NSString *itemTitle = item.title ? [item.title stringByConvertingHTMLToPlainText]:NSLocalizedString (@"MasterView_FeedNoTitle", nil);
        UIFont *font = [UIFont boldSystemFontOfSize:[self.dimensionsProvider dimensionByName:@"TableView_TitleSize"]];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        
        NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:itemTitle attributes:attributes];
        
        if (item.summary) {
            font = [UIFont systemFontOfSize:[self.dimensionsProvider dimensionByName:@"TableView_SubtitleSize"]];
            attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
            NSMutableAttributedString *summary = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", [[item.summary stringByConvertingHTMLToPlainText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]] attributes:attributes];
            
            [title appendAttributedString:summary];
        }
        
        cell.textLabel.attributedText = title;
        
        if (item.date) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [self.formatter stringFromDate:item.date]];
        }
    }
    
    return cell;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    return 80;
//}

 #pragma mark Table view delegate
/*
 - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
	// Show detail
//	GGRSSDetailViewController *detail = [[GGRSSDetailViewController alloc] init];
//	detail.item = (MWFeedItem *)[self.itemsToDisplay objectAtIndex:indexPath.row];
//	[self.navigationController pushViewController:detail animated:YES];
	
	// Deselect
//	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];	
 }*/

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        MWFeedItem *item = self.itemsToDisplay[indexPath.row];
        [[segue destinationViewController] setDetailItem:item];
    }
    
//    if ([[segue identifier] isEqualToString:@"showSettings"]) {
//        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
//        GGRSSAddFeedViewController *controller = (GGRSSAddFeedViewController *)navController.topViewController;
//        controller.url = ![self.feedParser.url isEqual:self.feeds.lastUsedUrl] ? self.feedParser.url : nil;
//    }
}

- (IBAction)unwindToMasterView:(UIStoryboardSegue *)segue
{
    id <GGRSSFeedUrlSource> sourse = [segue sourceViewController];
    NSURL *newUrl = sourse.url;
    if (newUrl != nil && ![self.feedParser.url isEqual:newUrl]) {
        [self setParserWithUrl:newUrl];
    }
}

@end

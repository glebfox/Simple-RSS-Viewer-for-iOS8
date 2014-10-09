//
//  GGRSSTitlesViewController.m
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 22.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSMasterViewController.h"
#import "GGRSSDetailViewController.h"
#import "GGRSSFeedsCollection.h"
#import "GGRSSDimensionsProvider.h"
#import "GGRSSFeedsTableViewController.h"
#import "GGRSSFeedUrlSource.h"
#import "GGRSSFeedParser.h"
#import "NSString+HTML.h"

NSString *oKey = @"feeds";

@interface GGRSSMasterViewController () <GGRSSFeedParserDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) GGRSSFeedParser *feedParser;
@property (strong, nonatomic) NSMutableArray *parsedItems;
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (strong, nonatomic) NSArray *itemsToDisplay;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic) BOOL isNewFeedParsing;

@end

@implementation GGRSSMasterViewController

#pragma mark - View lifecycle

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Иниализируем активити индикатор
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    // Получаем последний загруженный адрес на фид
    NSURL *feedURL = [[GGRSSFeedsCollection sharedInstance] lastUsedUrl];
    [[GGRSSFeedsCollection sharedInstance] addObserver:self forKeyPath:oKey options:NSKeyValueObservingOptionNew context:nil];
    [self setParserWithUrl:feedURL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Parsing

// Создает новый парсер с указанным url
- (void)setParserWithUrl:(NSURL *)url
{
    if (url != nil) {
        // Обновляем заголовок формы, запускаем анимацию и скрываем таблицу, чтобы было видно анимацию
        self.title = NSLocalizedString (@"MasterViewTitle_Loading", nil);
        [self.spinner startAnimating];
        self.tableView.hidden = YES;
    
        // Если не первый запуск, то останавливаем прерыдущий парсинг и обнуляем парсер
        if (self.feedParser != nil) {
            [self.feedParser stopParsing];
            self.feedParser = nil;
        }
        
        self.feedParser = [[GGRSSFeedParser alloc] initWithFeedURL:url];
        self.feedParser.delegate = self;
        self.parsedItems = nil;
        self.parsedItems = [NSMutableArray new];
        self.isNewFeedParsing = YES;
        [self.feedParser parse];
    } else {
        
    }
}

// Обвновляем таблицу текущим фидом
- (void)refresh
{
    if (self.feedParser) {
        self.title = NSLocalizedString (@"MasterViewTitle_Refreshing", nil);
        [self.parsedItems removeAllObjects];
        [self.feedParser stopParsing];
        self.isNewFeedParsing = NO;
        [self.feedParser parse];
    } else {
        [self.refreshControl endRefreshing];
    }
}

- (void)updateTableWithParsedItems
{
    // Сортируем элементы по дате
    self.itemsToDisplay = [self.parsedItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]]];
    [self.tableView reloadData];
    // Отображаем таблицу и завершаем анимации обновления
    self.tableView.hidden = NO;
    [self.refreshControl endRefreshing];
    [self.spinner stopAnimating];
    // Перемещаем фокут к самой верхней записи
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

#pragma mark - GGRSSFeedParserDelegate

- (void)feedParserDidStart:(GGRSSFeedParser *)parser
{
//    NSLog(@"Started Parsing: %@", parser.url);
    [[GGRSSFeedsCollection sharedInstance] setLastUsedUrl:self.feedParser.url];
}

- (void)feedParser:(GGRSSFeedParser *)parser didParseFeedInfo:(GGRSSFeedInfo *)info
{
//    NSLog(@"Parsed Feed Info: “%@”", info.title);
    if (self.isNewFeedParsing) {
        [[GGRSSFeedsCollection sharedInstance] addFeedWithTitle:info.title url:[info.url absoluteString]];
        self.isNewFeedParsing = NO;
    }
    self.title = info.title;
}

- (void)feedParser:(GGRSSFeedParser *)parser didParseFeedItem:(GGRSSFeedItemInfo *)item
{
//    NSLog(@"Parsed Feed Item: “%@”", item.title);
    if (item) [self.parsedItems addObject:item];
}

- (void)feedParserDidFinish:(GGRSSFeedParser *)parser
{
//    NSLog(@"Finished Parsing%@", (parser.stopped ? @" (Stopped)" : @""));
//    NSLog(@"Finished Parsing");
    [self updateTableWithParsedItems];
}

- (void)feedParser:(GGRSSFeedParser *)parser didFailWithError:(NSError *)error
{
    // В случае ошибки формируем предупреждение для пользователя
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString (@"AlertViewParsingIncomplete_Title", nil)
                                                    message:NSLocalizedString (@"AlertViewParsingIncomplete_Message", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString (@"AlertViewParsingIncomplete_CancelButtonTitle", nil)
                                          otherButtonTitles:nil];
    // Очищаем итемы для отображения, чтобы таблица оказалась пустой
    if (self.parsedItems.count > 0)
        [self.parsedItems removeAllObjects];
    [alert show];
    self.title = NSLocalizedString (@"MasterViewTitle_Failed", nil);
    [self updateTableWithParsedItems];
    [[GGRSSFeedsCollection sharedInstance] setLastUsedUrl:nil];
    
//    UIAlertController * alertController=   [UIAlertController
//                                  alertControllerWithTitle:NSLocalizedString (@"AlertViewParsingIncomplete_Title", nil)
//                                  message:NSLocalizedString (@"AlertViewParsingIncomplete_Message", nil)
//                                  preferredStyle:UIAlertControllerStyleAlert];
//    
//    UIAlertAction* cancel = [UIAlertAction
//                             actionWithTitle:NSLocalizedString (@"AlertViewParsingIncomplete_CancelButtonTitle", nil)
//                             style:UIAlertActionStyleDefault
//                             handler:^(UIAlertAction * action)
//                             {
//                                 [alertController dismissViewControllerAnimated:YES completion:nil];
//                                 
//                             }];
//    [alertController addAction:cancel];
//    
//    [self presentViewController:alertController animated:YES completion:nil];
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
    
    if (cell != nil) {
        // Configure the cell...
        GGRSSFeedItemInfo *item = [self.itemsToDisplay objectAtIndex:indexPath.row];
        if (item) {
            // Заголовок строки = заголовок новости. Полужирное начертание
            NSString *itemTitle = item.title ? [item.title stringByConvertingHTMLToPlainText]:NSLocalizedString (@"MasterView_FeedNoTitle", nil);
            UIFont *font = [UIFont boldSystemFontOfSize:[[GGRSSDimensionsProvider sharedInstance] dimensionByName:@"MasterTableView_TitleSize"]];
        
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        
            NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:itemTitle attributes:attributes];
        
            // Оставшееся место в заголовке строки заполняем описанием новости. Обычное написание, шрифт поменьше.
            if (item.summary) {
                font = [UIFont systemFontOfSize:[[GGRSSDimensionsProvider sharedInstance] dimensionByName:@"MasterTableView_SummarySize"]];
                attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
                NSMutableAttributedString *summary = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", [[item.summary stringByConvertingHTMLToPlainText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]] attributes:attributes];
            
                [title appendAttributedString:summary];
            }
            cell.textLabel.attributedText = title;
        
            // Подзаголовок строки = дата новости
            if (item.date) {
                // Инициализируем форматтер даты и времени
                self.formatter = [NSDateFormatter new];
                [self.formatter setDateStyle:NSDateFormatterShortStyle];
                [self.formatter setTimeStyle:NSDateFormatterShortStyle];
            
                cell.detailTextLabel.font = font = [UIFont systemFontOfSize:[[GGRSSDimensionsProvider sharedInstance] dimensionByName:@"MasterTableView_SubtitleSize"]];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [self.formatter stringFromDate:item.date]];
            }
        }
    }
    
    return cell;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:oKey]) {
        if ([self lastUsedFeedDeleted]) {
            [[GGRSSFeedsCollection sharedInstance] setLastUsedUrl:nil];
            self.itemsToDisplay = nil;
            self.feedParser = nil;
            self.title = @"";
            [self.tableView reloadData];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (BOOL)lastUsedFeedDeleted
{
    NSArray *feeds = [[GGRSSFeedsCollection sharedInstance] allFeeds];
    if (feeds == nil || feeds.count == 0) return YES;
    
    for (GGRSSFeedInfo *feed in feeds) {
        if ([feed.url isEqual:self.feedParser.url]) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Если мы переходим к детальному представлению, то передаем ему информацию по выбранной новости
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        GGRSSFeedItemInfo *item = self.itemsToDisplay[indexPath.row];
        if ([segue.destinationViewController class] == [GGRSSDetailViewController class]) {
            [segue.destinationViewController setDetailItem:item];
        }
    }
    
    if ([[segue identifier] isEqualToString:@"showFeeds"]) {
        if ([segue.destinationViewController class] == [GGRSSFeedsTableViewController class]) {
            [segue.destinationViewController setFeedsToDisplay:[[GGRSSFeedsCollection sharedInstance] allFeeds]];
        }
    }
    
    // На память, как добраться до вьювера через его Навигейшн контроллер
//    if ([[segue identifier] isEqualToString:@"showSettings"]) {
//        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
//        GGRSSAddFeedViewController *controller = (GGRSSAddFeedViewController *)navController.topViewController;
//        controller.url = ![self.feedParser.url isEqual:self.feeds.lastUsedUrl] ? self.feedParser.url : nil;
//    }
}

- (IBAction)unwindToMasterView:(UIStoryboardSegue *)segue
{
    // Вне зависимости от того с какой формы мы вернулись в главной, они должны поддерживать протокол, который предусматривает наличие ссылки на url
    if ([[segue.sourceViewController class] conformsToProtocol:@protocol(GGRSSFeedUrlSource)]) {
        id <GGRSSFeedUrlSource> sourse = [segue sourceViewController];
        NSURL *newUrl = sourse.url;
        // Поэтому, если url не пустой и не равен уже загруженному фиду, то запускаем новый парсинг
        if (newUrl != nil && ![self.feedParser.url isEqual:newUrl]) {
            [self setParserWithUrl:newUrl];
        }
    }
}

@end

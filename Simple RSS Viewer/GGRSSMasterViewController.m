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
#import "GGRSSFeedsTableViewController.h"
#import "GGRSSFeedUrlSource.h"
#import "NSString+HTML.h"

@interface GGRSSMasterViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) GGRSSFeedParser *feedParser;
@property (strong, nonatomic) NSMutableArray *parsedItems;
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (strong, nonatomic) NSArray *itemsToDisplay;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (nonatomic, getter=isNewFeedParsing) BOOL newFeedParsing;

@end

@implementation GGRSSMasterViewController

#pragma mark - init

- (id)init {
    if ((self = [super init])) {
        [self ggrssMasterViewInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self ggrssMasterViewInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        [self ggrssMasterViewInit];
    }
    return self;
}

- (void) ggrssMasterViewInit {
//    NSLog(@"ggrssMasterViewInit");
    // Инициализируем форматтер даты и времени
    self.formatter = [NSDateFormatter new];
    [self.formatter setDateStyle:NSDateFormatterShortStyle];
    [self.formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedsDidChanged:) name:GGRSSFeedsCollectionChangedNotification object:nil];
}

#pragma mark - View lifecycle

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"master - viewDidLoad");
    // Иниализируем активити индикатор
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    if (self.newFeedParsing) {
        [self prepareUIforParsing];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Parsing

// Создает новый парсер с указанным url
- (void)setParserWithUrl:(NSURL *)url delegate:(id<GGRSSFeedParserDelegate>)delegate
{
    if (url != nil) {
        // Обновляем заголовок формы, запускаем анимацию и скрываем таблицу, чтобы было видно анимацию
        self.title = NSLocalizedString (@"MasterViewTitle_Loading", nil);
        [self prepareUIforParsing];

        // Если не первый запуск, то останавливаем прерыдущий парсинг и обнуляем парсер
        if (self.feedParser != nil) {
            [self.feedParser stopParsing];
            self.feedParser.url = url;
        } else {
            self.feedParser = [[GGRSSFeedParser alloc] initWithFeedURL:url];
        }
        self.feedParser.delegate = delegate;
        self.parsedItems = nil;
        self.parsedItems = [NSMutableArray new];
        self.newFeedParsing = YES;
        [self.feedParser parse];
    }
}

// Обвновляем таблицу текущим фидом
- (void)refresh
{
    if (self.feedParser) {
        self.title = NSLocalizedString (@"MasterViewTitle_Refreshing", nil);
        [self.parsedItems removeAllObjects];
        [self.feedParser stopParsing];
        self.newFeedParsing = NO;
        [self.feedParser parse];
    } else {
        [self.refreshControl endRefreshing];
    }
}

- (void)updateTableWithParsedItems
{
    NSLog(@"updateTableWithParsedItems");
    // Сортируем элементы по дате
    self.itemsToDisplay = [self.parsedItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]]];
    [self.tableView reloadData];
    // Отображаем таблицу и завершаем анимации обновления
    self.tableView.hidden = NO;
    // Перемещаем фокут к самой верхней записи
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)prepareUIforParsing {
    [self.spinner startAnimating];
    self.tableView.hidden = YES;
}

#pragma mark - GGRSSFeedParserDelegate

- (void)feedParserDidStart:(GGRSSFeedParser *)parser
{
    NSLog(@"Started Parsing: %@", parser.url);
    [[GGRSSFeedsCollection sharedInstance] setLastUsedUrl:self.feedParser.url];
}

- (void)feedParser:(GGRSSFeedParser *)parser didParseFeedInfo:(GGRSSFeedInfo *)info
{
    NSLog(@"Parsed Feed Info: “%@”", info.title);
    if (self.isNewFeedParsing) {
        [[GGRSSFeedsCollection sharedInstance] addFeedWithTitle:info.title url:[info.url absoluteString]];
        self.newFeedParsing = NO;
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
    NSLog(@"Finished Parsing");
    
    [self.refreshControl endRefreshing];
    [self updateTableWithParsedItems];    
    [self.spinner stopAnimating];
}

- (void)feedParser:(GGRSSFeedParser *)parser didFailWithError:(NSError *)error
{
    // В случае ошибки формируем предупреждение для пользователя
    // Если UIAlertController существует, значит версия >= iOS8
    if ([UIAlertController class]) {
        NSLog(@"UIAlertController");
        UIAlertController * alertController=   [UIAlertController
                                                alertControllerWithTitle:NSLocalizedString (@"AlertViewParsingIncomplete_Title", nil)
                                                message:[error localizedDescription]
                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString (@"AlertViewParsingIncomplete_CancelButtonTitle", nil)
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
        [alertController addAction:cancel];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {    // Иначе версия < iOS8
        NSLog(@"UIAlertView");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString (@"AlertViewParsingIncomplete_Title", nil)
                                                        message: [error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString (@"AlertViewParsingIncomplete_CancelButtonTitle", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    // Очищаем итемы для отображения, чтобы таблица оказалась пустой
    if (self.parsedItems.count > 0)
        [self.parsedItems removeAllObjects];
    
    self.title = NSLocalizedString (@"MasterViewTitle_Failed", nil);
    [self feedParserDidFinish:parser];    
    [[GGRSSFeedsCollection sharedInstance] setLastUsedUrl:nil];
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
//    NSLog(@"cellForRowAtIndexPath");
    static NSString *CellIdentider = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentider forIndexPath:indexPath];
    
    if (cell != nil) {
        // Configure the cell...
        GGRSSFeedItemInfo *item = [self.itemsToDisplay objectAtIndex:indexPath.row];
        if (item) {
            // Заголовок строки = заголовок новости. Полужирное начертание
            NSString *itemTitle = item.title ? [item.title stringByConvertingHTMLToPlainText]:NSLocalizedString (@"MasterView_FeedNoTitle", nil);
            UIFont *font = [UIFont boldSystemFontOfSize:14];
        
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        
            NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:itemTitle attributes:attributes];
        
            // Оставшееся место в заголовке строки заполняем описанием новости. Обычное написание, шрифт поменьше.
            if (item.summary) {
                font = [UIFont systemFontOfSize:12];
                attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
                NSMutableAttributedString *summary = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", [[item.summary stringByConvertingHTMLToPlainText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]] attributes:attributes];
            
                [title appendAttributedString:summary];
            }
            cell.textLabel.attributedText = title;
        
            // Подзаголовок строки = дата новости
            if (item.date) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [self.formatter stringFromDate:item.date]];
            }
        }
    }
    
    return cell;
}

#pragma mark - GGRSSFeedsCollectionNotification

- (void)feedsDidChanged:(NSNotification *)notification {
    // Если вдруг удалили из списка активный фид, то очищаем таблицу и заносим пустую ссылку в ресурсы
    if ([self lastUsedFeedDeleted]) {
        [[GGRSSFeedsCollection sharedInstance] setLastUsedUrl:nil];
        self.itemsToDisplay = nil;
        self.feedParser = nil;
        self.title = @"";
        [self.tableView reloadData];
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
        if (newUrl != nil ) { //&& ![self.feedParser.url isEqual:newUrl]
            [self setParserWithUrl:newUrl delegate:self];
        }
    }
}

@end

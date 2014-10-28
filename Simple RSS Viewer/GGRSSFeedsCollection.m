//
//  GGRSSFeedsCollection.m
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 25.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSFeedsCollection.h"

NSString *const GGRSSFeedsCollectionChangedNotification = @"GGRSSFeedsCollectionChangedNotification";

@interface GGRSSFeedsCollection ()

@property (nonatomic, strong) NSMutableDictionary *feeds;   // Список сохраненных фидов
@property (nonatomic, strong) NSArray *feedsArray;
@property (nonatomic, strong) NSString *feedsPath;  // Путь до файла с списком фидов в документах юзера
@property (nonatomic, strong) NSString *urlPath;    // Путь до файла с списком фидов в документах юзера
@property (nonatomic, getter=isFeedsChanged) BOOL feedsChanged; // Признак, того что надо заново скомпоновать allFeeds
@property (nonatomic, strong) NSNotification *notification;

@end

@implementation GGRSSFeedsCollection

@synthesize lastUsedUrl;

+ (id)sharedInstance
{
    static GGRSSFeedsCollection *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        // Узнаем пусть до документов пользователя
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Если приложение запускается впервые, то копируем ресурсы в документы
        NSError *error;
        self.feedsPath = [documentsDirectory stringByAppendingPathComponent:@"FeedsUrl.plist"];
        if (![fileManager fileExistsAtPath: self.feedsPath])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"FeedsUrl" ofType:@"plist"];
            [fileManager copyItemAtPath:bundle toPath: self.feedsPath error:&error];
            if (error) NSLog(@"%@", error);
        }
        // Получаем список фидов из документов
        self.feeds = [NSMutableDictionary dictionaryWithContentsOfFile:self.feedsPath];
        
        // То же самое проделываем для ресурсов с последней использованной ссылкой
        error = nil;
        self.urlPath = [documentsDirectory stringByAppendingPathComponent:@"FeedsLastUrl.plist"];
        if (![fileManager fileExistsAtPath:self.urlPath]) {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"FeedsLastUrl" ofType:@"plist"];
            [fileManager copyItemAtPath:bundle toPath: self.urlPath error:&error];
            if (error) NSLog(@"%@", error);
        }
        
        self.notification = [NSNotification notificationWithName:GGRSSFeedsCollectionChangedNotification object:self];
    }
    return self;
}

- (NSURL *) lastUsedUrl
{
    NSArray *url = [NSArray arrayWithContentsOfFile:self.urlPath];
    NSString *urlStrind = url[0];
    // Если что то в ресурсах есть, то превращаем это в ссылку, иначе возвращаем nil
    lastUsedUrl = urlStrind.length > 0 ? [NSURL URLWithString:url[0]] : nil;
    
    return lastUsedUrl;
}

- (void) setLastUsedUrl:(NSURL *)url
{
    // Если ссылка новая
    if (![url isEqual:lastUsedUrl]) {
        NSString *urlString;
        // Если ссылки нету, то будет сохранять пустую строку, чтобы в слдующий раз никакой фид не загружался
        if (url == nil) {
            urlString = @"";
        } else {
            // или получаем строку с адресом
            urlString = [url absoluteString];
        }
        lastUsedUrl = url;
        
        NSError *error;
        NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:@[urlString] format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        // Если есть что сохранять
        if(xmlData) {
            [xmlData writeToFile:self.urlPath atomically:YES];
        }
        else {
            NSLog(@"%@", error);
        }
    }
}

- (void)addFeedWithTitle:(NSString *)title url:(NSString *)urlString
{
    NSString *value = self.feeds[title];
    // Если нам есть что сохранять и данные уникальные (на уникальность проверяется только адрес)
    if (value == nil || ![value isEqualToString:urlString]) {
        [self.feeds setObject:urlString forKey:title];
        [self saveFeeds];
        
        self.feedsChanged = true;
        [[NSNotificationCenter defaultCenter] postNotification:self.notification];
    }
}

- (void)deleteFeedWithTitle:(NSString *)title
{
    [self.feeds removeObjectForKey:title];
    [self saveFeeds];
    
    self.feedsChanged = true;
    [[NSNotificationCenter defaultCenter] postNotification:self.notification];
}

/*
 Формирует из словаря массив GGRSSFeedInfo для удобной обработки контроллерами
 */
- (NSArray *)allFeeds
{
    // нет смысла каждый раз копировать
    NSArray *keys = [self.feeds allKeys];
    if (keys.count > 0) {
        if (!self.feedsArray || self.isFeedsChanged) {
            NSMutableArray *feeds = [NSMutableArray new];
            for (NSString *key in keys) {
                GGRSSFeedInfo *info = [GGRSSFeedInfo new];
                info.title = key;
                info.url = [NSURL URLWithString:self.feeds[key]];
                [feeds addObject:info];
            }
            self.feedsChanged = false;
            self.feedsArray = [feeds copy];
        }
        return self.feedsArray;
    }
    return nil;
}

- (void)saveFeeds
{
    NSError *error;
    NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:self.feeds format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if(xmlData) {
        [xmlData writeToFile:self.feedsPath atomically:YES];
    }
    else {
        NSLog(@"%@", error);
    }
}

@end

//
//  GGRSSFeedsCollection.m
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 25.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSFeedsCollection.h"

@interface GGRSSFeedsCollection () {
    NSURL *_lastUsedUrl;
}

@property (nonatomic, strong) NSMutableDictionary *feeds;
@property (nonatomic, strong) NSString *feedsPath;
@property (nonatomic, strong) NSString *urlPath;

@end

@implementation GGRSSFeedsCollection

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
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"FeedsUrl" ofType:@"plist"];
//        self.feeds = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        
        
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        self.feedsPath = [documentsDirectory stringByAppendingPathComponent:@"FeedsUrl.plist"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath: self.feedsPath])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"FeedsUrl" ofType:@"plist"];
            [fileManager copyItemAtPath:bundle toPath: self.feedsPath error:&error];
        }
        self.feeds = [NSMutableDictionary dictionaryWithContentsOfFile:self.feedsPath];
        if (error) {
            NSLog(@"%@", error);
        }
        
        error = nil;
        self.urlPath = [documentsDirectory stringByAppendingPathComponent:@"FeedsLastUrl.plist"];
        if (![fileManager fileExistsAtPath:self.urlPath]) {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"FeedsLastUrl" ofType:@"plist"];
            [fileManager copyItemAtPath:bundle toPath: self.urlPath error:&error];
        }
        if (error) {
            NSLog(@"%@", error);
        }
    }
    return self;
}

- (NSURL *) lastUsedUrl
{
    NSArray *url = [NSArray arrayWithContentsOfFile:self.urlPath];
    NSString *urlStrind = url[0];
    _lastUsedUrl = urlStrind.length > 0 ? [NSURL URLWithString:url[0]] : nil;
    
    return _lastUsedUrl;
}

- (void) setLastUsedUrl:(NSURL *)url
{
    if (![url isEqual:_lastUsedUrl]) {
        NSString *urlString;
        if (url == nil) {
            urlString = @"";
        } else {
            urlString = [url absoluteString];
        }
        _lastUsedUrl = url;
        
        NSError *error;
        NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:@[urlString] format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        
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
//    NSLog(@"addFeedWithTitle - %@", self.observationInfo);
//    NSLog(@"addFeedWithTitle");
    NSString *value = self.feeds[title];
    if (value == nil || ![value isEqualToString:urlString]) {
//        NSLog(@"addFeedWithTitle - added");
        [self willChangeValueForKey:@"feeds"];
        [self.feeds setObject:urlString forKey:title];
        [self saveFeeds];
        [self didChangeValueForKey:@"feeds"];
    }
}

- (void)deleteFeedWithTitle:(NSString *)title
{
//    NSLog(@"deleteFeedWithTitle - %@", self.observationInfo);
    [self willChangeValueForKey:@"feeds"];
    [self.feeds removeObjectForKey:title];
    [self saveFeeds];
    [self didChangeValueForKey:@"feeds"];
    
}

- (NSArray *)allFeeds
{
    NSArray *keys = [self.feeds allKeys];
    if (keys.count > 0) {
        NSMutableArray *feeds = [NSMutableArray new];
        
        for (NSString *key in keys) {
            GGRSSFeedInfo *info = [GGRSSFeedInfo new];
            info.title = key;
            info.url = [NSURL URLWithString:self.feeds[key]];
            [feeds addObject:info];
        }
        
        return [feeds copy];
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

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@"feeds"]) {
        return NO;
    } else {
        return [super automaticallyNotifiesObserversForKey:key];
    }
}

@end

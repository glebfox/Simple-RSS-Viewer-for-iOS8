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

@property(nonatomic, retain) NSMutableDictionary *feeds;

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
        NSString *path = [[NSBundle mainBundle] pathForResource:@"FeedsUrl" ofType:@"plist"];
        self.feeds = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    }
    return self;
}

- (NSURL *) lastUsedUrl
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"FeedsLastUrl" ofType:@"plist"];
    NSArray *url = [NSArray arrayWithContentsOfFile:path];
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
        NSString *path = [[NSBundle mainBundle] pathForResource:@"FeedsLastUrl" ofType:@"plist"];
        NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:@[urlString] format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        
        if(xmlData) {
            [xmlData writeToFile:path atomically:YES];
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
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"FeedsUrl" ofType:@"plist"];
    NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:self.feeds format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if(xmlData) {
        [xmlData writeToFile:path atomically:YES];
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

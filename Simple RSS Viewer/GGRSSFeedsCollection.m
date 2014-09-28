//
//  GGRSSFeedsCollection.m
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 25.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSFeedsCollection.h"

@interface GGRSSFeedsCollection ()

@property(nonatomic, retain) NSString *path;
@property(nonatomic, retain) NSMutableArray *feeds;

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
        self.path = [[NSBundle mainBundle] pathForResource:@"FeedsUrl" ofType:@"plist"];
        self.feeds = [NSMutableArray arrayWithContentsOfFile:self.path];
        
    }
    return self;
}

-(NSURL *) lastUsedUrl
{
    if (self.feeds.count != 0) {
        return [NSURL URLWithString:self.feeds[0][1]];
    }
    return nil;
}

- (void)addFeedWithTitle:(NSString *)title absoluteUrlString:(NSString *)urlString
{
    if ([self.feeds[0][1] isEqualToString:urlString]) {
        return;
    }
    
    for (int i = 0; i < self.feeds.count; i++) {
        if ([self.feeds[i][1] isEqualToString:urlString]) {
            [self.feeds removeObjectAtIndex:i];
        }
    }
    
    [self.feeds insertObject:@[title, urlString] atIndex:0];
}

- (NSArray *)allFeeds
{
    return self.feeds;
}

- (void)saveFeeds
{
    NSError *error;
    
    NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:self.feeds format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if(xmlData) {
        [xmlData writeToFile:self.path atomically:YES];
    }
    else {
        NSLog(@"%@", error);
    }
}

- (void)deleteFeedAtIndex:(NSUInteger)index
{
    [self.feeds removeObjectAtIndex:index];
}

@end

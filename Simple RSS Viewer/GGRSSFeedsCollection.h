//
//  GGRSSFeedsCollection.h
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 25.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGRSSFeedsCollection : NSObject

+ (id)sharedInstance;

- (NSURL *)lastUsedUrl;
- (void)addFeedWithTitle:(NSString *)title absoluteUrlString:(NSString *)urlString;
- (NSArray *)allFeeds;
- (void)deleteFeedAtIndex:(NSUInteger)index;
- (void)saveFeeds;

@end

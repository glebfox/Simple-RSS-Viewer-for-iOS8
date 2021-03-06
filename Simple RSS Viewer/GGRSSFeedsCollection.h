//
//  GGRSSFeedsCollection.h
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 25.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGRSSFeedInfo.h"



@interface GGRSSFeedsCollection : NSObject

+ (id)sharedInstance;

@property (nonatomic, strong) NSURL *lastUsedUrl;

- (void)addFeedWithTitle:(NSString *)title url:(NSString *)urlString;
- (NSArray *)allFeeds;
- (void)deleteFeedWithTitle:(NSString *)title;
- (void)saveFeeds;

@end

NSString *const GGRSSFeedsCollectionChangedNotification;    // UIKIT_EXTERN - надо?

//
//  GGRSSFeedsTableViewController.h
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 25.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GGRSSFeedUrlSource.h"

@interface GGRSSFeedsTableViewController : UITableViewController <GGRSSFeedUrlSource>

@property (nonatomic, strong) NSArray *feedsToDisplay;   // Список фидов для отображения

@end

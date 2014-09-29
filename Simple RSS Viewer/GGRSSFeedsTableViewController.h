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

@property NSURL *url;   // Адрес к которому обратится главная форма, когда будет выбрана ячейка в таблице

// Позволяет вернуться к списку фидов с формы добавления нового фида
- (IBAction)unwindToFeeds:(UIStoryboardSegue *)segue;

@end

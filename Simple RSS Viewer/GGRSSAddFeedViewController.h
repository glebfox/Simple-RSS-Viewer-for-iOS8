//
//  GGRSSSettingsViewController.h
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 23.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GGRSSFeedUrlSource.h"

@interface GGRSSAddFeedViewController : UITableViewController <GGRSSFeedUrlSource>

@property NSURL *url;

@end

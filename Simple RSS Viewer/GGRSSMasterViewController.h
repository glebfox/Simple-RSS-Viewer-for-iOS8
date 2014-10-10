//
//  GGRSSTitlesViewController.h
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 22.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GGRSSFeedParser.h"

@interface GGRSSMasterViewController : UIViewController <GGRSSFeedParserDelegate>

- (void)setParserWithUrl:(NSURL *)url delegate:(id<GGRSSFeedParserDelegate>)delegate;

@end

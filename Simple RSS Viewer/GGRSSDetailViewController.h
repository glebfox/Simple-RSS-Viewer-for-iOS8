//
//  GGRSSDetailViewController.h
//  Simple RSS Viewer
//
//  Created by Gorelov on 9/19/14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWFeedItem.h"

@interface GGRSSDetailViewController : UIViewController

@property (nonatomic, strong) MWFeedItem *detailItem;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

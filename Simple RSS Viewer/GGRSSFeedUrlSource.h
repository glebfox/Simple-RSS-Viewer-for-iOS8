//
//  GGRSSFeedUrlSource.h
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 26.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GGRSSFeedUrlSource <NSObject>

@property(nonatomic, strong) NSURL *url;

@end

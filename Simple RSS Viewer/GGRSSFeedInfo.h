//
//  GGRSSFeedInfo.h
//  XML Parser
//
//  Created by Gleb Gorelov on 05.10.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGRSSFeedInfo : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSURL *link;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSURL *url;

@end

//
//  GGRSSFeedItemInfo.m
//  XML Parser
//
//  Created by Gleb Gorelov on 05.10.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSFeedItemInfo.h"

@implementation GGRSSFeedItemInfo

- (NSString *)description
{
    NSMutableString *string = [[NSMutableString alloc] initWithString:@"GGRSSFeedItemInfo: "];
    if (self.title)   [string appendFormat:@"“%@”", self.title];
//    if (date)    [string appendFormat:@" - %@", date];
//    if (self.link)    [string appendFormat:@" (%@)", self.link];
//    if (self.summary) [string appendFormat:@", %@", self.summary];
    return string;
}

@end

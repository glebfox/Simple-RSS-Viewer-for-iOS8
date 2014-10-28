//
//  GGRSSFeedInfo.m
//  XML Parser
//
//  Created by Gleb Gorelov on 05.10.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSFeedInfo.h"

@implementation GGRSSFeedInfo

#pragma mark NSObject

- (NSString *)description {
    NSMutableString *string = [[NSMutableString alloc] initWithString:@"GGRSSFeedInfo: "];
    if (self.title)   [string appendFormat:@"“%@”", self.title];
    if (self.url)    [string appendFormat:@" (%@)", self.url];
    //if (self.summary) [string appendFormat:@", %@", self.summary];
    return string;
}

@end

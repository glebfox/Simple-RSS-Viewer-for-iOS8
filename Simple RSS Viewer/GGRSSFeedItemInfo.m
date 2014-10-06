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

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) {
        self.title = [decoder decodeObjectForKey:@"title"];
        self.link = [decoder decodeObjectForKey:@"link"];
        self.date = [decoder decodeObjectForKey:@"date"];
        self.summary = [decoder decodeObjectForKey:@"summary"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    if (self.title) [encoder encodeObject:self.title forKey:@"title"];
    if (self.link) [encoder encodeObject:self.link forKey:@"link"];
    if (self.date) [encoder encodeObject:self.date forKey:@"date"];
    if (self.summary) [encoder encodeObject:self.summary forKey:@"summary"];
}

@end

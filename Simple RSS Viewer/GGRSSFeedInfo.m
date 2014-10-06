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
    //if (self.link)    [string appendFormat:@" (%@)", link];
    //if (self.summary) [string appendFormat:@", %@", summary];
    return string;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) {
        self.title = [decoder decodeObjectForKey:@"title"];
        self.link = [decoder decodeObjectForKey:@"link"];
        self.summary = [decoder decodeObjectForKey:@"summary"];
        self.url = [decoder decodeObjectForKey:@"url"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    if (self.title) [encoder encodeObject:self.title forKey:@"title"];
    if (self.link) [encoder encodeObject:self.link forKey:@"link"];
    if (self.summary) [encoder encodeObject:self.summary forKey:@"summary"];
    if (self.url) [encoder encodeObject:self.url forKey:@"url"];
}

@end

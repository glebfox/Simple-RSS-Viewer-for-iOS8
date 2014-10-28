//
//  GGRSSFeedParser.h
//  XML Parser
//
//  Created by Gleb Gorelov on 05.10.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGRSSFeedInfo.h"
#import "GGRSSFeedItemInfo.h"

// Коды ошибок
enum
{
    GGRSS_ERROR_CODE_NOT_INITIATED,
    GGRSS_ERROR_CODE_CONNECTION_FAILED,
    GGRSS_ERROR_CODE_XML_PARSING_ERROR
};

@class GGRSSFeedParser;

@protocol GGRSSFeedParserDelegate <NSObject>

@optional
- (void)feedParserDidStart:(GGRSSFeedParser *)parser;
- (void)feedParser:(GGRSSFeedParser *)parser didParseFeedInfo:(GGRSSFeedInfo *)feed;
- (void)feedParser:(GGRSSFeedParser *)parser didParseFeedItem:(GGRSSFeedItemInfo *)item;
- (void)feedParserDidFinish:(GGRSSFeedParser *)parser;
- (void)feedParser:(GGRSSFeedParser *)parser didFailWithError:(NSError *)error;
@end

@interface GGRSSFeedParser : NSObject

@property (nonatomic, weak) id <GGRSSFeedParserDelegate> delegate;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSURLRequest *request;

- (id)initWithFeedURL:(NSURL *)feedURL;
- (BOOL)parse;
- (void)stopParsing;
//- (NSURL *)url;

@end

NSString *const GGRSSFeedParserBackgroundSessionIdentifier;

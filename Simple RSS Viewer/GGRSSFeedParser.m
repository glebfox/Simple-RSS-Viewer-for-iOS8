//
//  GGRSSFeedParser.m
//  XML Parser
//
//  Created by Gleb Gorelov on 05.10.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSFeedParser.h"
#import "NSDate+InternetDateTime.h"

#define GGRSSErrorCodeNotInitiated      1
#define GGRSSErrorCodeConnectionFailed  2
#define GGRSSErrorCodeXmlParsingError   3

@interface GGRSSFeedParser () <NSXMLParserDelegate>

// Feed Downloading Properties
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, strong) NSMutableData *asyncData;

// Parsing Properties
@property NSXMLParser *xmlParser;
@property GGRSSFeedInfo *feedInfo;
@property GGRSSFeedItemInfo *currentFeedItemInfo;
@property NSMutableString *foundCharacters;
@property BOOL isItem;

@property NSDateFormatter *dateFormatterRFC822;

@end

@implementation GGRSSFeedParser

- (id)init
{
    if ((self = [super init])) {
        // Date Formatters
        // Good info on internet dates here: http://developer.apple.com/iphone/library/qa/qa2010/qa1480.html
        NSLocale *en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        self.dateFormatterRFC822 = [[NSDateFormatter alloc] init];
        [self.dateFormatterRFC822 setLocale:en_US_POSIX];
        [self.dateFormatterRFC822 setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return self;
}

// Initialise with a URL
- (id)initWithFeedURL:(NSURL *)feedURL {
    if ((self = [self init])) {
        
        // URL
        if ([feedURL isKindOfClass:[NSString class]]) {
            feedURL = [NSURL URLWithString:(NSString *)feedURL];
        }
        self.url = feedURL;

        // Create default request with no caching
        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:self.url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                            timeoutInterval:60];
        self.request = req;
        
    }
    return self;
}

// Init with a custom feed request
- (id)initWithFeedRequest:(NSMutableURLRequest *)feedRequest {
    if (self = [self init]) {
        self.url = feedRequest.URL;
        self.request = feedRequest;
    }
    return self;
}

#pragma mark - Parsing

// Reset data variables before processing
// Exclude parse state variables as they are needed after parse
- (void)reset {
    self.asyncData = nil;
    self.urlConnection = nil;
    self.foundCharacters = nil;
    self.currentFeedItemInfo = nil;
    self.feedInfo = nil;
    self.isItem = NO;
}

// Parse using URL for backwards compatibility
- (BOOL)parse {
    
    if (!self.url || !self.delegate) {
        [self parsingFailedWithErrorCode:GGRSSErrorCodeNotInitiated andDescription:@"Delegate or URL not specified"];
        return NO;
    }
    
    // Reset
    [self reset];
    
    // Async
    self.asyncData = [[NSMutableData alloc] init];  // Create data
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
    if (self.urlConnection) {
        return YES;
    } else {
        [self parsingFailedWithErrorCode:GGRSSErrorCodeConnectionFailed
                          andDescription:[NSString stringWithFormat:@"Asynchronous connection failed to URL: %@", self.url]];
        self.asyncData = nil;
        return NO;
    }
}

// Begin XML parsing
- (void)startParsingData:(NSData *)data {
    
        if (data) {
            
            // Create feed info
            GGRSSFeedInfo *feedInfo = [[GGRSSFeedInfo alloc] init];
            self.foundCharacters = [[NSMutableString alloc] init];
            feedInfo.url = self.url;
            self.feedInfo = feedInfo;
            
            // Create NSXMLParser
            NSXMLParser *newXmlParser = [[NSXMLParser alloc] initWithData:data];
            self.xmlParser = newXmlParser;
            if (self.xmlParser) {
                
                // Parse!
                self.xmlParser.delegate = self;
                [self.xmlParser parse];
                self.xmlParser = nil; // Release after parse
                
            } else {
                [self parsingFailedWithErrorCode:GGRSSErrorCodeXmlParsingError andDescription:@"Feed not a valid XML document"];
            }
        } else {
            [self parsingFailedWithErrorCode:GGRSSErrorCodeXmlParsingError andDescription:@"Error with feed encoding"];
        }
}

// Stop parsing
- (void)stopParsing {
    [self.xmlParser abortParsing];
}

// Finished parsing document successfully
- (void)parsingFinished {
    if ([self.delegate respondsToSelector:@selector(feedParserDidFinish:)])
        [self.delegate feedParserDidFinish:self];
    
    // Reset
    [self reset];
}

// If an error occurs, create NSError and inform delegate
- (void)parsingFailedWithErrorCode:(int)code andDescription:(NSString *)description {
        // Create error
    NSError *error = [NSError errorWithDomain:@"GGRSSFeedParser"
                              code:code
                              userInfo:[NSDictionary dictionaryWithObject:description
                              forKey:NSLocalizedDescriptionKey]];
        
    // Abort parsing
    if (self.xmlParser) {
        [self.xmlParser abortParsing];
    }
    
    // Reset
    [self reset];
    
    // Inform delegate
    if ([self.delegate respondsToSelector:@selector(feedParser:didFailWithError:)])
        [self.delegate feedParser:self didFailWithError:error];
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    //    NSLog(@"didStartElement: %@ namespaceURI: %@ qualifiedName: %@ attributes: %@", elementName, namespaceURI, qName, attributeDict);
    [self.foundCharacters setString:@""];
    
    if ([elementName isEqualToString:@"channel"]) {
        self.isItem = NO;
    } else if ([elementName isEqualToString:@"item"]) {
        self.isItem = YES;
        self.currentFeedItemInfo = [GGRSSFeedItemInfo new];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    //    NSLog(@"foundCharacters: %@", string);
    [self.foundCharacters appendString:string];
}

- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString
{
    NSLog(@"foundIgnorableWhitespace: %@", whitespaceString);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"title"]) {
        self.isItem ? (self.currentFeedItemInfo.title = self.foundCharacters) : (self.feedInfo.title = self.foundCharacters);
    }
    
    if ([elementName isEqualToString:@"link"]) {
        NSURL *url = [NSURL URLWithString:[self.foundCharacters stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        self.isItem ? (self.currentFeedItemInfo.link = url) : (self.feedInfo.link = url);
    }
    
    if ([elementName isEqualToString:@"description"]) {
        self.isItem ? (self.currentFeedItemInfo.summary = self.foundCharacters) : (self.feedInfo.summary = self.foundCharacters);
    }
    
    if ([elementName isEqualToString:@"pubDate"]) {
        NSDate *date = [NSDate dateFromInternetDateTimeString:self.foundCharacters formatHint:DateFormatHintRFC822];
                if (self.isItem) self.currentFeedItemInfo.date = date;
    }
    
    if ([elementName isEqualToString:@"item"]) {
        [self sendFeedItemToDelegate];
    }
    
    if ([elementName isEqualToString:@"channel"]) {
        [self sendFeedInfoToDelegate];
    }
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    
    // Inform delegate
    if ([self.delegate respondsToSelector:@selector(feedParserDidStart:)])
        [self.delegate feedParserDidStart:self];
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    // Inform delegate
    [self parsingFinished];
    
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [self parsingFailedWithErrorCode:GGRSSErrorCodeXmlParsingError andDescription:[parseError localizedDescription]];
}

#pragma mark - NSURLConnection Delegate (Async)

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.asyncData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.asyncData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self reset];
    [self parsingFailedWithErrorCode:GGRSSErrorCodeConnectionFailed andDescription:[error localizedDescription]];
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self startParsingData:self.asyncData];
    [self reset];
}



-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil; // Don't cache
}

#pragma mark - Send Items to Delegate

- (void)sendFeedInfoToDelegate {
    if (self.feedInfo) {
        
        // Inform delegate
        if ([self.delegate respondsToSelector:@selector(feedParser:didParseFeedInfo:)])
            [self.delegate feedParser:self didParseFeedInfo:self.feedInfo];
        
        // Finish
        self.feedInfo = nil;
        
    }
}

- (void)sendFeedItemToDelegate {
    if (self.currentFeedItemInfo) {
        
        // Inform delegate
        if ([self.delegate respondsToSelector:@selector(feedParser:didParseFeedItem:)])
            [self.delegate feedParser:self didParseFeedItem:self.currentFeedItemInfo];
        
        // Finish
        self.self.currentFeedItemInfo = nil;
    }
}

@end

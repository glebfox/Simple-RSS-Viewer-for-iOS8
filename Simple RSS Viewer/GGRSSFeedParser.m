//
//  GGRSSFeedParser.m
//  XML Parser
//
//  Created by Gleb Gorelov on 05.10.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSFeedParser.h"

@interface GGRSSFeedParser () <NSXMLParserDelegate>

// Feed Downloading Properties
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, strong) NSMutableData *asyncData;
@property (nonatomic, strong) NSString *asyncTextEncodingName;

// Parsing Properties
@property NSXMLParser *xmlParser;
@property GGRSSFeedInfo *feedInfo;
@property GGRSSFeedItemInfo *currentFeedItemInfo;
@property NSMutableString *foundCharacters;
@property BOOL isItem;

@end

@implementation GGRSSFeedParser

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
        [req setValue:@"GGRSSFeedParser" forHTTPHeaderField:@"User-Agent"];
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
    self.asyncTextEncodingName = nil;
    self.urlConnection = nil;
    self.foundCharacters = [[NSMutableString alloc] init];
    self.currentFeedItemInfo = nil;
    self.feedInfo = nil;
    self.isItem = NO;
}

// Parse using URL for backwards compatibility
- (BOOL)parse {
    
    // Reset
    [self reset];
    
//    if (self.xmlParser) // xmlParser is an NSXMLParser instance variable
//        self.xmlParser = nil;
//    self.xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:self.url];
//    [self.xmlParser setDelegate:self];
//    [self.xmlParser setShouldResolveExternalEntities:NO];
//    
//    self.feedInfo = [GGRSSFeedInfo new];
//    self.feedInfo.url = self.url;
//    
//    return [self.xmlParser parse]; // return value not used
//                                   // if not successful, delegate is informed of error
    
    // Async
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
    if (self.urlConnection) {
        self.asyncData = [[NSMutableData alloc] init];// Create data
    } else {
//        [self parsingFailedWithErrorCode:MWErrorCodeConnectionFailed
//                          andDescription:[NSString stringWithFormat:@"Asynchronous connection failed to URL: %@", url]];
        return NO;
    }
    
    return YES;
}

// Begin XML parsing
- (void)startParsingData:(NSData *)data textEncodingName:(NSString *)textEncodingName {
        
        // Create feed info
        GGRSSFeedInfo *feedInfo = [[GGRSSFeedInfo alloc] init];
        feedInfo.url = self.url;
        self.feedInfo = feedInfo;
        
//        // Check whether it's UTF-8
//        if (![[textEncodingName lowercaseString] isEqualToString:@"utf-8"]) {
//            
//            // Not UTF-8 so convert
//            NSString *string = nil;
//            
//            // Attempt to detect encoding from response header
//            NSStringEncoding nsEncoding = 0;
//            if (textEncodingName) {
//                CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)textEncodingName);
//                if (cfEncoding != kCFStringEncodingInvalidId) {
//                    nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
//                    if (nsEncoding != 0) string = [[NSString alloc] initWithData:data encoding:nsEncoding];
//                }
//            }
//            
//            // If that failed then make our own attempts
//            if (!string) {
//                // http://www.mikeash.com/pyblog/friday-qa-2010-02-19-character-encodings.html
//                string			    = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//                if (!string) string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
//                if (!string) string = [[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding];
//            }
//            
//            // Nil data
//            data = nil;
//            
//            // Parse
//            if (string) {
//                
//                // Set XML encoding to UTF-8
//                if ([string hasPrefix:@"<?xml"]) {
//                    NSRange a = [string rangeOfString:@"?>"];
//                    if (a.location != NSNotFound) {
//                        NSString *xmlDec = [string substringToIndex:a.location];
//                        if ([xmlDec rangeOfString:@"encoding=\"UTF-8\""
//                                          options:NSCaseInsensitiveSearch].location == NSNotFound) {
//                            NSRange b = [xmlDec rangeOfString:@"encoding=\""];
//                            if (b.location != NSNotFound) {
//                                NSUInteger s = b.location+b.length;
//                                NSRange c = [xmlDec rangeOfString:@"\"" options:0 range:NSMakeRange(s, [xmlDec length] - s)];
//                                if (c.location != NSNotFound) {
//                                    NSString *temp = [string stringByReplacingCharactersInRange:NSMakeRange(b.location,c.location+c.length-b.location)
//                                                                                     withString:@"encoding=\"UTF-8\""];
//                                    string = temp;
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                // Convert string to UTF-8 data
//                if (string) {
//                    data = [string dataUsingEncoding:NSUTF8StringEncoding];
//                }
//                
//            }
//        
        // Create NSXMLParser
        if (data) {
            NSXMLParser *newXmlParser = [[NSXMLParser alloc] initWithData:data];
            self.xmlParser = newXmlParser;
            if (self.xmlParser) {
                
                // Parse!
                self.xmlParser.delegate = self;
//                [self.xmlParser setShouldProcessNamespaces:YES];
                [self.xmlParser parse];
                self.xmlParser = nil; // Release after parse
                
            } else {
//                [self parsingFailedWithErrorCode:MWErrorCodeFeedParsingError andDescription:@"Feed not a valid XML document"];
            }
        } else {
//            [self parsingFailedWithErrorCode:MWErrorCodeFeedParsingError andDescription:@"Error with feed encoding"];
        }
}

// Stop parsing
- (void)stopParsing {
    [self.xmlParser abortParsing];
    [self parsingFinished];
}

// Finished parsing document successfully
- (void)parsingFinished {
    if ([self.delegate respondsToSelector:@selector(feedParserDidFinish:)])
        [self.delegate feedParserDidFinish:self];
    
    // Reset
    [self reset];
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
    //        NSLog(@"didEndElement: %@ namespaceURI: %@ qualifiedName: %@", elementName, namespaceURI, qName);
    
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
        //        if (self.isItem) self.currentFeedItemInfo.date = [NSDateFormatter da] self.foundCharacters;
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
    NSLog(@"parseErrorOccurred: %@", parseError);
}

#pragma mark - NSURLConnection Delegate (Async)

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.asyncData setLength:0];
    self.asyncTextEncodingName = [response textEncodingName];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.asyncData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    // Failed
    self.urlConnection = nil;
    self.asyncData = nil;
    self.asyncTextEncodingName = nil;
    
    // Error
//    [self parsingFailedWithErrorCode:MWErrorCodeConnectionFailed andDescription:[error localizedDescription]];
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Parse
//    if (!stopped) [self startParsingData:self.asyncData textEncodingName:self.asyncTextEncodingName];
    [self startParsingData:self.asyncData textEncodingName:self.asyncTextEncodingName];
    
    // Cleanup
    self.urlConnection = nil;
    self.asyncData = nil;
    self.asyncTextEncodingName = nil;
    
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

//
//  GGRSSFeedParser.m
//  XML Parser
//
//  Created by Gleb Gorelov on 05.10.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSFeedParser.h"
#import "NSDate+InternetDateTime.h"
#import "AppDelegate.h"

@interface GGRSSFeedParser () <NSXMLParserDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

// Свойства для скачивания инфы
//@property (nonatomic, copy) NSURL *url;
//@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSData *data;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

// Свойства для процесса парсинга
@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) GGRSSFeedInfo *feedInfo;
@property (nonatomic, strong) GGRSSFeedItemInfo *currentFeedItemInfo;
@property (nonatomic, strong) NSMutableString *foundCharacters;
@property (nonatomic) BOOL isItem;

@property NSDateFormatter *dateFormatterRFC822;

@end

@implementation GGRSSFeedParser

- (id)init
{
    if ((self = [super init])) {
        // http://developer.apple.com/iphone/library/qa/qa2010/qa1480.html
        NSLocale *en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        self.dateFormatterRFC822 = [[NSDateFormatter alloc] init];
        [self.dateFormatterRFC822 setLocale:en_US_POSIX];
        [self.dateFormatterRFC822 setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        self.session = [self backgroundSession];
    }
    return self;
}

- (id)initWithFeedURL:(NSURL *)feedURL {
    if ((self = [self init])) {
        
        // URL
        if ([feedURL isKindOfClass:[NSString class]]) {
            feedURL = [NSURL URLWithString:(NSString *)feedURL];
        }
        self.url = feedURL;

        // Создаем request
//        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:self.url
//                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
//                                                            timeoutInterval:60];
//        self.request = req;
        
    }
    return self;
}

- (id)initWithFeedRequest:(NSMutableURLRequest *)feedRequest {
    if (self = [self init]) {
//        self.url = feedRequest.URL;
        self.request = feedRequest;
    }
    return self;
}

#pragma mark - Parsing

- (NSURLSession *)backgroundSession
{
    /*
     Using disptach_once here ensures that multiple background sessions with the same identifier are not created in this instance of the application. If you want to support multiple background sessions within a single process, you should create each session with its own identifier.
     */
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.gorelov.SimpleRSSViewer.BackgroundSession"];
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    });
    
    return session;
}

- (void)reset {
    self.foundCharacters = nil;
    self.currentFeedItemInfo = nil;
    self.feedInfo = nil;
    self.isItem = NO;
    self.downloadTask = nil;
}

- (BOOL)parse {
    
    if (!self.url || !self.delegate) {
        [self parsingFailedWithErrorCode:GGRSS_ERROR_CODE_NOT_INITIATED andDescription:NSLocalizedString(@"Delegate or URL not specified", nil)];
        return NO;
    }
    
    [self reset];
    
    self.downloadTask = [self.session downloadTaskWithRequest:self.request];
    [self.downloadTask resume];
    
    return YES;
}

// После того, как данные загрузятся из инета, этот метод разберет XML текст на состовляющие
- (void)startParsingData:(NSData *)data {
    NSLog(@"startParsingData");
    if (data) {
        
        // Если данные есть, то должна быть и информация про фид
        GGRSSFeedInfo *feedInfo = [[GGRSSFeedInfo alloc] init];
        self.foundCharacters = [[NSMutableString alloc] init];
        feedInfo.url = self.url;
        self.feedInfo = feedInfo;
        
        // Создаем NSXMLParser
        NSXMLParser *newXmlParser = [[NSXMLParser alloc] initWithData:data];
        self.xmlParser = newXmlParser;
        if (self.xmlParser) {
            
            // Запускаем парсинг
            self.xmlParser.delegate = self;
            [self.xmlParser parse];
            self.xmlParser = nil;
            
        } else {
            [self parsingFailedWithErrorCode:GGRSS_ERROR_CODE_XML_PARSING_ERROR andDescription:NSLocalizedString(@"Feed not a valid XML document", nil)];
        }
    } else {
        [self parsingFailedWithErrorCode:GGRSS_ERROR_CODE_XML_PARSING_ERROR andDescription:NSLocalizedString(@"Error with feed encoding", nil)];
    }
}

- (void)stopParsing {
    [self.xmlParser abortParsing];
}

// Если успешно завершили парсинг, сообщаем об этом делегату
- (void)parsingFinished {
    if ([self.delegate respondsToSelector:@selector(feedParserDidFinish:)])
        [self.delegate feedParserDidFinish:self];

    [self reset];
}

// В случае ошибок, создаем NSError и отпраляем делегату
- (void)parsingFailedWithErrorCode:(int)code andDescription:(NSString *)description {
    NSLog(@"parsingFailedWithErrorCode: code = %d", code);
    NSLog(@"parsingFailedWithErrorCode: description = %@", description);
    NSError *error = [NSError errorWithDomain:@"GGRSSFeedParser"
                              code:code
                              userInfo:[NSDictionary dictionaryWithObject:description
                              forKey:NSLocalizedDescriptionKey]];
    
    if (self.xmlParser) {
        [self.xmlParser abortParsing];
    }
    
    [self reset];
    
    if ([self.delegate respondsToSelector:@selector(feedParser:didFailWithError:)])
        [self.delegate feedParser:self didFailWithError:error];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    /*
     Report progress on the task.
     If you created more than one task, you might keep references to them and report on them individually.
     */
    
    if (downloadTask == self.downloadTask)
    {
        double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
        NSLog(@"progress: %lf", progress);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.progressView.progress = progress;
//        });
    }
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL
{
    /*
     The download completed, you need to copy the file at targetPath before the end of this block.
     As an example, copy the file to the Documents directory of your app.
     */
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    
//    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
//    NSURL *documentsDirectory = [URLs objectAtIndex:0];
//    
//    NSURL *originalURL = [[downloadTask originalRequest] URL];
//    NSURL *destinationURL = [documentsDirectory URLByAppendingPathComponent:[originalURL lastPathComponent]];
//    NSError *errorCopy;
//    
//    // For the purposes of testing, remove any esisting file at the destination.
//    [fileManager removeItemAtURL:destinationURL error:NULL];
//    BOOL success = [fileManager copyItemAtURL:downloadURL toURL:destinationURL error:&errorCopy];
//    
//    if (success)
//    {
    NSData *data = [NSData dataWithContentsOfURL:downloadURL];
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self startParsingData:[NSData dataWithContentsOfFile:[destinationURL path]]];
            [self startParsingData:data];
            [self reset];
        });
//    }
//    else
//    {
//        /*
//         In the general case, what you might do in the event of failure depends on the error and the specifics of your application.
//         */
//        NSLog(@"Error during the copy: %@", [errorCopy localizedDescription]);
//    }
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error)
        [self parsingFailedWithErrorCode:GGRSS_ERROR_CODE_CONNECTION_FAILED
                          andDescription:[NSString stringWithFormat:NSLocalizedString(@"Asynchronous connection failed to URL: %@", nil), self.url]];
}


/*
 If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message, the session delegate will receive this message to indicate that all messages previously enqueued for this session have been delivered. At this time it is safe to invoke the previously stored completion handler, or to begin any internal updates that will result in invoking the completion handler.
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
    
    NSLog(@"All tasks are finished");
}


//-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
//{
//    
//}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    [self.foundCharacters setString:@""];

    // Если бывл начат новый item, то создаем экземпляр GGRSSFeedItemInfo
    if ([elementName isEqualToString:@"channel"]) {
        self.isItem = NO;
    } else if ([elementName isEqualToString:@"item"]) {
        self.isItem = YES;
        self.currentFeedItemInfo = [GGRSSFeedItemInfo new];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
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
    
    // Если завершили парсить итем или фид инфо, отправляем уведомление делегату
    if ([elementName isEqualToString:@"item"]) {
        [self sendFeedItemToDelegate];
    }
    
    if ([elementName isEqualToString:@"channel"]) {
        [self sendFeedInfoToDelegate];
    }
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    if ([self.delegate respondsToSelector:@selector(feedParserDidStart:)])
        [self.delegate feedParserDidStart:self];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self parsingFinished];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [self parsingFailedWithErrorCode:GGRSS_ERROR_CODE_XML_PARSING_ERROR andDescription:[parseError localizedDescription]];
}

#pragma mark - Send Items to Delegate

- (void)sendFeedInfoToDelegate {
    if (self.feedInfo) {
        if ([self.delegate respondsToSelector:@selector(feedParser:didParseFeedInfo:)])
            [self.delegate feedParser:self didParseFeedInfo:self.feedInfo];
        self.feedInfo = nil;
        
    }
}

- (void)sendFeedItemToDelegate {
    if (self.currentFeedItemInfo) {
        if ([self.delegate respondsToSelector:@selector(feedParser:didParseFeedItem:)])
            [self.delegate feedParser:self didParseFeedItem:self.currentFeedItemInfo];
        self.self.currentFeedItemInfo = nil;
    }
}

#pragma mark - NSURL and NSURLRequest

- (void)setUrl:(NSURL *)url {
    _url = url;
    _request = [NSURLRequest requestWithURL:self.url];
}

- (void)setRequest:(NSURLRequest *)request {
    _request = request;
    _url = self.request.URL;
}

@end

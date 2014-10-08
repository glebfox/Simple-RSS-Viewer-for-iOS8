//
//  GGRSSDimensionsProvider.m
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 26.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//


#import "GGRSSDimensionsProvider.h"

@interface GGRSSDimensionsProvider ()

@property(nonatomic, strong) NSDictionary *dimensions;

@end

@implementation GGRSSDimensionsProvider

+ (id)sharedInstance
{
    static GGRSSDimensionsProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Dimensions" ofType:@"plist"];
        self.dimensions = [NSDictionary dictionaryWithContentsOfFile:path];
        
    }
    return self;
}

- (float)dimensionByName:(NSString *)name
{
    return [self.dimensions[name] floatValue];
}

@end

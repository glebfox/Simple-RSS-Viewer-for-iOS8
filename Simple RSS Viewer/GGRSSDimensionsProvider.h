//
//  GGRSSDimensionsProvider.h
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 26.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGRSSDimensionsProvider : NSObject

+ (id)sharedInstance;

- (float)dimensionByName:(NSString *)name;

@end

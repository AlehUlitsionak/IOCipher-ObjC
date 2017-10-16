//
//  DDSFile.m
//  StorageFramework
//
//  Created by rent on 10/1/17.
//  Copyright © 2017 SibEDGE. All rights reserved.
//

#import "DDSFile.h"

@implementation DDSFile

- (instancetype) initWithFileName:(NSString*)fileName {
    if (self = [super init]) {
        _uuid = [[NSUUID UUID] UUIDString];
        _fileName = fileName;
    }
    return self;
}

- (NSString*) description {
    NSString *description = [[super description] stringByAppendingFormat:@": %@", self.virtualPath];
    return description;
}

- (BOOL)isEqualToFile:(DDSFile *)file {
    return [self.virtualPath isEqualToString:file.virtualPath];
}

@end

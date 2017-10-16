//
//  DDSFile.h
//  StorageFramework
//
//  Created by rent on 10/1/17.
//  Copyright © 2017 SibEDGE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDSFile : NSObject

@property (nonatomic, assign) NSUInteger fileSize;
@property (nonatomic, assign) NSUInteger fileAllocatedSize;
@property (nonatomic, strong) DDSFile *parent;
@property (nonatomic, strong) NSArray *children;
@property (nonatomic, assign) BOOL isFolder;

@property (nonatomic, strong) NSString *virtualPath;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong, readonly) NSString *uuid;

- (instancetype) initWithFileName:(NSString*)fileName;

- (BOOL)isEqualToFile:(DDSFile *)file;

@end

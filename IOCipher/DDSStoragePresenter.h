//
//  FolderInfoPresenter.h
//  StorageFramework
//
//  Created by rent on 9/29/17.
//  Copyright © 2017 SibEDGE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSFile.h"

typedef NS_ENUM(NSInteger, DDSFileAccessType) {
    kDDSFileAccessTypeRead,
    kDDSFileAccessTypeEdit,
    kDDSFileAccessTypeSave,
    kDDSFileAccessTypeRename,
    kDDSFileAccessTypeMove,
    kDDSFileAccessTypeDelete
};

@protocol DDSStorageDelegate <NSObject>
 @optional
- (void)didUpdateStorage:(NSArray *_Nullable)files;
- (void)accessUpdate:(NSDictionary *_Nullable)update toFileAtPath:(NSString*_Nonnull)path;
@end

@interface DDSStoragePresenter : NSObject

@property (nonatomic, weak) id <DDSStorageDelegate> _Nullable delegate;

/* returns array of DDSFile objects */
- (NSArray*_Nullable)fileSystemRootHierarchy:(NSError *_Nullable*_Nullable)error;
- (NSArray*_Nullable)contentsOfFolerAtPath:(NSString*_Nonnull)path error:(NSError *_Nullable*_Nullable)error;

/* apps who access files are responsible to call this methods */
- (void)applicationWithName:(NSString *_Nonnull)applicationName accessesFile:(DDSFile *_Nonnull)file withFileAccessType:(DDSFileAccessType)accessType;
- (void)applicationWithName:(NSString *_Nonnull)applicationName didFinishAccessingFile:(DDSFile *_Nonnull)file withFileAccessType:(DDSFileAccessType)accessType;


- (void)readFileAtPath:(NSString*_Nonnull)path completionHandler:(void (^_Nonnull)(NSData*_Nullable, NSError* _Nullable))callbackBlock;
- (void)saveFile:(NSData*_Nonnull)data atPath:(NSString*_Nonnull)path completionHandler:(void (^_Nonnull)(BOOL, NSError* _Nullable))callbackBlock;

- (BOOL)createFolderAtPath:(NSString*_Nonnull)path error:(NSError*_Nullable*_Nullable)error;
- (BOOL)deleteItem:(DDSFile*_Nonnull)item error:(NSError *_Nullable __autoreleasing *_Nullable)error;

/* This methods aren't working
- (void)startObservingFileAtPath:(NSString *_Nonnull)filePath;
- (void)stopObservingFileAtPath:(NSString *_Nonnull)filePath;
 */

@end

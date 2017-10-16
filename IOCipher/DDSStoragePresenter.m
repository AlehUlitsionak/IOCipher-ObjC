//
//  FolderInfoPresenter.m
//  StorageFramework
//
//  Created by rent on 9/29/17.
//  Copyright © 2017 SibEDGE. All rights reserved.
//

#import "DDSStoragePresenter.h"
#import "DDSConstants.h"
#import "IOCipher.h"

@interface DDSStoragePresenter ()
@property (nonatomic, strong) IOCipher *iocipher;
@property (nonatomic, strong) NSMutableArray *virtualFiles;
@end

@implementation DDSStoragePresenter {
    
    NSURL* _folderURL;
    
    struct {
        unsigned int didUpdateStorage:1;
        unsigned int accessUpdateToFileAtPath:2;
    } delegateRespondsTo;

}

- (void)setDelegate:(id <DDSStorageDelegate>)aDelegate {
    if (_delegate != aDelegate) {
        _delegate = aDelegate;
        
        delegateRespondsTo.didUpdateStorage = [_delegate respondsToSelector:@selector(didUpdateStorage:)];
        delegateRespondsTo.accessUpdateToFileAtPath = [_delegate respondsToSelector:@selector(accessUpdate:toFileAtPath:)];
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) init {
    self = [super init];
    if ( self == nil )
        return ( nil );
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSURL *groupUrl = [fileManager containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
    
    /* temporary use Documents forlder for debug purposes */
    NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    groupUrl = [paths lastObject];
    
    NSURL *storagePathUrl = [groupUrl URLByAppendingPathComponent:@"DDStorage"];
    NSString *storagePath = storagePathUrl.path;
    
    if (![fileManager fileExistsAtPath:storagePath]) {
        NSError *error;
        [fileManager createDirectoryAtPath:storagePath withIntermediateDirectories:false attributes:nil error:&error];
    }
    
    _folderURL = storagePathUrl;
    
    [self setupIOCipherWithGroupFolder:storagePath];
    
    /* This adds files for test purposes */
//    NSArray *files = [[NSBundle mainBundle] pathsForResourcesOfType:nil inDirectory:@"samples"];
//    [files enumerateObjectsUsingBlock:^(NSString *filePath, NSUInteger idx, BOOL *stop) {
//        [self addLocalFileToEncryptedStore:filePath];
//    }];
    
    return self;
}

- (void) addLocalFileToEncryptedStore:(NSString*)localFilePath {
    
    NSString *fileName = [localFilePath lastPathComponent];
    DDSFile *virtualFile = [[DDSFile alloc] initWithFileName:fileName];
    NSError *error = nil;
    
    NSData *fileData = [NSData dataWithContentsOfFile:localFilePath];
    [self.iocipher writeDataToFileAtPath:[@"/" stringByAppendingString:virtualFile.fileName] data:fileData offset:0 error:&error];
    if (error) {
        NSLog(@"Error writing file data");
        return;
    }
    
    [self.iocipher createFolderAtPath:@"/FolderExample" error:&error];
    [self.iocipher createFolderAtPath:@"/FolderExample/Subfolder" error:&error];
    
    fileData = [NSData dataWithContentsOfFile:localFilePath];
    [self.iocipher writeDataToFileAtPath:[@"/FolderExample/Subfolder/" stringByAppendingString:@"Readme.txt"] data:fileData offset:0 error:&error];
   
}

- (void) setupIOCipherWithGroupFolder:(NSString *)path {
    
    NSString *dbPath = [path stringByAppendingPathComponent:@"vfs.sqlite"];
    self.iocipher = [[IOCipher alloc] initWithPath:dbPath password:@"test"];
}

- (NSArray*)fileSystemRootHierarchy:(NSError**)error {
    
    NSArray* result = [self.iocipher filesAtPath:@"/" error:error];
    return result;
}

- (NSArray*_Nullable)contentsOfFolerAtPath:(NSString*_Nonnull)path error:(NSError *_Nullable*_Nullable)error {
    
    NSArray* result = [self.iocipher filesAtPath:path error:error];
    return result;
}

- (void)applicationWithName:(NSString *)applicationName accessesFile:(DDSFile *)file withFileAccessType:(DDSFileAccessType)accessType {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; //[[NSUserDefaults alloc] initWithSuiteName:kAppGroupIdentifier];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if ([defaults dictionaryForKey:file.virtualPath] != nil) {
        params = [[defaults dictionaryForKey:file.virtualPath] mutableCopy];
    }
    
    NSString *value = accessType == kDDSFileAccessTypeRead ? @"Reading" : (accessType == kDDSFileAccessTypeSave ? @"Writing" : @"Editing");
    params[applicationName] = value;
    [defaults setObject:params forKey:file.virtualPath];
    [defaults synchronize];
}

- (void)applicationWithName:(NSString *)applicationName didFinishAccessingFile:(DDSFile *)file withFileAccessType:(DDSFileAccessType)accessType {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; //[[NSUserDefaults alloc] initWithSuiteName:kAppGroupIdentifier];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if ([defaults dictionaryForKey:file.virtualPath] != nil) {
        params = [[defaults dictionaryForKey:file.virtualPath] mutableCopy];
    }
    if (params != nil) {
        [params removeObjectForKey:applicationName];
        [defaults setObject:params forKey:file.virtualPath];
        [defaults synchronize];
    }
}

- (void)readFileAtPath:(NSString*)path completionHandler:(void (^)(NSData*, NSError* _Nullable))callbackBlock {
    
    NSError *error = nil;
    NSData *data = [self.iocipher readDataFromFileAtPath:path error:&error];
    callbackBlock(data, error);
}

- (void)saveFile:(NSData*)data atPath:(NSString*)path completionHandler:(void (^)(BOOL, NSError* _Nullable))callbackBlock {
    
    NSError *error = nil;
    NSInteger result = [self.iocipher writeDataToFileAtPath:path data:data offset:0 error:&error];
    callbackBlock(result >= 0, error);
}

- (BOOL)createFolderAtPath:(NSString*)path error:(NSError **)error {

    if ([self.iocipher createFolderAtPath:path error:error]) {
        if (delegateRespondsTo.didUpdateStorage) {
            [self.delegate didUpdateStorage:[self fileSystemRootHierarchy:nil]];
        }
        return YES;
    }
    return NO;
}

- (BOOL)deleteItem:(DDSFile*_Nonnull)item error:(NSError *_Nullable __autoreleasing *_Nullable)error {

    if (item.children.count > 0) {
        [item.children enumerateObjectsUsingBlock:^(DDSFile *_Nonnull child, NSUInteger idx, BOOL * _Nonnull stop) {
            [self deleteItem:child error:error];
        }];
    }

    if ([self.iocipher removeItemAtPath:item.virtualPath error:error]) {
        if (delegateRespondsTo.didUpdateStorage) {
            [self.delegate didUpdateStorage:[self fileSystemRootHierarchy:nil]];
        }
        return YES;
    }
    return NO;
}

/* This methonds don't work for some reason - not even with standardUserDefaults
-(void)startObservingFileAtPath:(NSString *_Nonnull)filePath {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; //[[NSUserDefaults alloc] initWithSuiteName:kAppGroupIdentifier];
    [defaults addObserver:self forKeyPath:filePath options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
}

- (void)stopObservingFileAtPath:(NSString *_Nonnull)filePath {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; //[[NSUserDefaults alloc] initWithSuiteName:kAppGroupIdentifier];
    [defaults removeObserver:self forKeyPath:filePath context:NULL];
}
 */

// KVO handler
-(void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject
                       change:(NSDictionary *)aChange context:(void *)aContext
{
    if (delegateRespondsTo.accessUpdateToFileAtPath) {
        [self.delegate accessUpdate:aChange toFileAtPath:aKeyPath];
    }
}

- (void)defaultsChanged:(NSNotification *)notification {
    
    if (delegateRespondsTo.accessUpdateToFileAtPath) {
        NSUserDefaults *defaults = (NSUserDefaults *)[notification object];
        [self.delegate accessUpdate:defaults.dictionaryRepresentation toFileAtPath:@""];
    }
    
}

@end

//
//  ImageCacheManager.m
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import "ImageCacheManager.h"
#import <CommonCrypto/CommonDigest.h>

@interface ImageCacheManager ()
@property (nonatomic, strong) NSCache<NSString *, UIImage *> *memoryCache;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSURL *cacheDirectory;
@end

@implementation ImageCacheManager

+ (instancetype)sharedManager {
    static ImageCacheManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ImageCacheManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _memoryCache = [[NSCache alloc] init];
        _fileManager = [NSFileManager defaultManager];
        // 磁盘缓存路径
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [paths.firstObject stringByAppendingPathComponent:@"ImageCache"];
        _cacheDirectory = [NSURL fileURLWithPath:cachePath];
        // 创建目录
        if (![_fileManager fileExistsAtPath:cachePath]) {
            [_fileManager createDirectoryAtURL:_cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return self;
}

- (UIImage *)getImageFromMemoryForKey:(NSString *)key {
    return [self.memoryCache objectForKey:key];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key {
    if (!image || !key) return;
    [self.memoryCache setObject:image forKey:key];
    // 异步写入磁盘
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *data = UIImageJPEGRepresentation(image, 0.8);
        if (data) {
            NSURL *fileURL = [self.cacheDirectory URLByAppendingPathComponent:[self md5String:key]];
            [data writeToURL:fileURL atomically:YES];
        }
    });
}

- (UIImage *)getImageFromDiskForKey:(NSString *)key {
    NSURL *fileURL = [self.cacheDirectory URLByAppendingPathComponent:[self md5String:key]];
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    if (data) {
        return [UIImage imageWithData:data];
    }
    return nil;
}

// MD5 辅助方法
- (NSString *)md5String:(NSString *)string {
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

@end

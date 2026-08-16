//
//  ImageCacheManager.h
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageCacheManager : NSObject

+ (instancetype)sharedManager;

/// 从内存缓存取图
- (nullable UIImage *)getImageFromMemoryForKey:(NSString *)key;
/// 存入内存缓存（并异步写入磁盘）
- (void)setImage:(UIImage *)image forKey:(NSString *)key;
/// 从磁盘缓存取图
- (nullable UIImage *)getImageFromDiskForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

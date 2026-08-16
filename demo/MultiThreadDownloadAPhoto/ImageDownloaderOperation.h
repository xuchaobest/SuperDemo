//
//  ImageDownloaderOperation.h
//  demo
//
//  Created by RichardX on 2026/8/4.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageDownloaderWithOperation : NSObject

/**
 批量下载图片，所有下载完成后横向拼接为一张大图
 @param imageURLs 图片URL字符串数组
 @param completion 完成回调（主线程执行）
 */
- (void)downloadAndCompositeWithURLs:(NSArray<NSString *> *)imageURLs
                          completion:(void (^)(UIImage * _Nullable compositeImage))completion;

@end

NS_ASSUME_NONNULL_END

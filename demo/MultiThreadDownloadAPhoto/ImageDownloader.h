//
//  ImageDownloader.h
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageDownloader : NSObject

/// 批量下载图片，全部完成后合成一张大图（横向拼接），通过 completion 回调
- (void)downloadAndCompositeWithURLs:(NSArray<NSString *> *)imageURLs
                          completion:(void (^)(UIImage * _Nullable compositeImage))completion;

@end

NS_ASSUME_NONNULL_END

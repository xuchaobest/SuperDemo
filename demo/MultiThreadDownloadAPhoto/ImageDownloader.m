//
//  ImageDownloader.m
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import "ImageDownloader.h"

@interface ImageDownloader ()
// 合成图片私有方法
- (UIImage *)compositeImages:(NSArray<UIImage *> *)images;
@end

@implementation ImageDownloader

- (void)downloadAndCompositeWithURLs:(NSArray<NSString *> *)imageURLs
                          completion:(void (^)(UIImage * _Nullable))completion {
    if (!imageURLs.count) {
        if (completion) completion(nil);
        return;
    }
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(5); // 最大并发5
    NSLock *lock = [[NSLock alloc] init];
    NSMutableArray<UIImage *> *downloadedImages = [NSMutableArray array];
    
    for (NSString *urlString in imageURLs) {
        dispatch_group_enter(group);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url) {
            dispatch_semaphore_signal(semaphore);
            dispatch_group_leave(group);
            continue;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 模拟网络请求（实际项目中建议使用 NSURLSession 异步）
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *image = nil;
            if (data) {
                image = [UIImage imageWithData:data];
            }
            
            if (image) {
                [lock lock];
                [downloadedImages addObject:image];
                [lock unlock];
            }
            
            dispatch_semaphore_signal(semaphore);
            dispatch_group_leave(group);
        });
    }
    
    UIImage *composite;
    if (downloadedImages.count) {
        composite = [self compositeImages:downloadedImages];
    }

    // 全部完成后的回调
    dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
        UIImage *composite;
        if (downloadedImages.count) {
            composite = [self compositeImages:downloadedImages];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!composite) {
                if (completion) completion(nil);
                return;
            }
            
            if (completion) completion(composite);
        });
    });
}

- (UIImage *)compositeImages:(NSArray<UIImage *> *)images {
    if (images.count == 0) return nil;
    
    // 计算总宽度和最大高度（横向拼接）
    CGFloat totalWidth = 0;
    CGFloat maxHeight = 0;
    for (UIImage *img in images) {
        totalWidth += img.size.width;
        if (img.size.height > maxHeight) maxHeight = img.size.height;
    }
    
    CGSize size = CGSizeMake(totalWidth, maxHeight);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen new].scale);
    
    CGFloat xOffset = 0;
    for (UIImage *img in images) {
        [img drawAtPoint:CGPointMake(xOffset, 0)];
        xOffset += img.size.width;
    }
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@end

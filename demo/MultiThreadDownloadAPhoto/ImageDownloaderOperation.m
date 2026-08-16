//
//  ImageDownloaderOperation.m
//  demo
//
//  Created by RichardX on 2026/8/4.
//

#import "ImageDownloaderOperation.h"

@interface ImageDownloaderWithOperation ()
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@end

@implementation ImageDownloaderWithOperation

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.maxConcurrentOperationCount = 5; // 控制并发数
    }
    return self;
}

- (void)downloadAndCompositeWithURLs:(NSArray<NSString *> *)imageURLs
                          completion:(void (^)(UIImage * _Nullable))completion {
    if (imageURLs.count == 0) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
        return;
    }
    
    // 线程安全的图片收集器
    NSMutableArray<UIImage *> *downloadedImages = [NSMutableArray array];
    NSLock *lock = [[NSLock alloc] init];
    
    // 用于存放所有下载操作的数组（用于建立依赖）
    NSMutableArray<NSOperation *> *downloadOperations = [NSMutableArray arrayWithCapacity:imageURLs.count];
    
    // 1. 为每个 URL 创建下载操作
    for (NSString *urlString in imageURLs) {
        NSBlockOperation *downloadOp = [NSBlockOperation blockOperationWithBlock:^{
            // 模拟网络请求（同步阻塞方式，在后台线程执行）
            NSURL *url = [NSURL URLWithString:urlString];
            if (!url) return;
            
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *image = nil;
            if (data) {
                image = [UIImage imageWithData:data];
            }
            
            // 线程安全地添加到数组
            if (image) {
                [lock lock];
                [downloadedImages addObject:image];
                [lock unlock];
            }
        }];
        
        [downloadOperations addObject:downloadOp];
    }
    
    // 2. 创建合成操作，依赖于所有下载操作
    NSBlockOperation *compositeOp = [NSBlockOperation blockOperationWithBlock:^{
        // 合成图片（横向拼接）
        UIImage *composite = [self compositeImages:downloadedImages];
        
        // 回到主线程回调
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(composite);
            }
        });
    }];
    
    // 让合成操作依赖所有下载操作
    for (NSOperation *op in downloadOperations) {
        [compositeOp addDependency:op];
    }
    
    // 3. 将所有操作添加到队列
    // 注意：合成操作也要加入队列，否则不会执行
    for (NSOperation *op in downloadOperations) {
        [self.downloadQueue addOperation:op];
    }
    [self.downloadQueue addOperation:compositeOp];
}

#pragma mark - Private Methods

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

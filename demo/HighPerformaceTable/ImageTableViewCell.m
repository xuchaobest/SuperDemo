//
//  ImageTableViewCell.m
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import "ImageTableViewCell.h"
#import "ImageCacheManager.h"

@interface ImageTableViewCell ()
@property (nonatomic, copy) NSString *currentURL;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@end

@implementation ImageTableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.dataTask cancel];
    self.dataTask = nil;
    self.photoImageView.image = nil;
}

- (void)configureWithURLString:(NSString *)urlString {
    self.currentURL = urlString;
    self.photoImageView.image = nil; // 先置空
    
    // 1. 查内存缓存
    UIImage *cachedImage = [[ImageCacheManager sharedManager] getImageFromMemoryForKey:urlString];
    if (cachedImage) {
        self.photoImageView.image = cachedImage;
        return;
    }
    
    // 2. 查磁盘缓存
    UIImage *diskImage = [[ImageCacheManager sharedManager] getImageFromDiskForKey:urlString];
    if (diskImage) {
        [[ImageCacheManager sharedManager] setImage:diskImage forKey:urlString];
        self.photoImageView.image = diskImage;
        return;
    }
    
    // 3. 网络下载
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    
    __weak typeof(self) weakSelf = self;
    self.dataTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) return;
        UIImage *image = [UIImage imageWithData:data];
        if (!image) return;
        
        // 存入缓存
        [[ImageCacheManager sharedManager] setImage:image forKey:urlString];
        
        // 回到主线程更新 UI，并校验 URL 是否匹配
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            if ([strongSelf.currentURL isEqualToString:urlString]) {
                strongSelf.photoImageView.image = image;
            }
        });
    }];
    [self.dataTask resume];
}

@end

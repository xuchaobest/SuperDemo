//
//  LRUWeightedCache.h
//  demo
//
//  Created by RichardX on 2026/8/11.
//

#import <Foundation/Foundation.h>

@interface LRUWeightedCache : NSObject

/// 总权重上限（总资源阈值，如总字节数）
@property (nonatomic, assign) NSUInteger maxTotalWeight;
/// 当前已经占用总权重
@property (nonatomic, assign, readonly) NSUInteger currentTotalWeight;

- (instancetype)initWithMaxTotalWeight:(NSUInteger)maxWeight;

/// 获取缓存，命中更新访问时间
- (id)objectForKey:(id)key;

/// 设置缓存，传入该value对应的权重；内部自动做淘汰
- (void)setObject:(id)obj forKey:(id)key weight:(NSUInteger)weight;

/// 删除指定key
- (void)removeObjectForKey:(id)key;

/// 清空全部缓存
- (void)removeAllObjects;

/// 返回当前缓存item数量
- (NSInteger)cacheItemCount;

@end

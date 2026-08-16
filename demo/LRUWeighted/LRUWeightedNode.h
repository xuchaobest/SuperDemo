//
//  LRUWeightedNode.h
//  demo
//
//  Created by RichardX on 2026/8/11.
//

#import <Foundation/Foundation.h>

@interface LRUWeightedNode : NSObject

@property (nonatomic, copy) id key;
@property (nonatomic, strong) id value;
/// 当前条目权重：代表资源开销，比如图片内存size、对象预估内存
@property (nonatomic, assign) NSUInteger weight;
/// 访问时间戳，记录最后一次访问
@property (nonatomic, assign) NSTimeInterval lastAccessTs;

@property (nonatomic, weak) LRUWeightedNode *prev;
@property (nonatomic, weak) LRUWeightedNode *next;

- (instancetype)initWithKey:(id)key value:(id)value weight:(NSUInteger)weight;

@end

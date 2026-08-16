//
//  LRUWeightedCache.m
//  demo
//
//  Created by RichardX on 2026/8/11.
//

#import "LRUWeightedCache.h"
#import "LRUWeightedNode.h"

@interface LRUWeightedCache ()

@property (nonatomic, strong) NSMutableDictionary *hashMap;
/// 双向链表哨兵
@property (nonatomic, strong) LRUWeightedNode *head;
@property (nonatomic, strong) LRUWeightedNode *tail;
@property (nonatomic, assign, readwrite) NSUInteger currentTotalWeight;

@end

@implementation LRUWeightedCache

- (instancetype)initWithMaxTotalWeight:(NSUInteger)maxWeight {
    NSAssert(maxWeight > 0, @"maxTotalWeight必须大于0");
    self = [super init];
    if (self) {
        _maxTotalWeight = maxWeight;
        _currentTotalWeight = 0;
        _hashMap = [NSMutableDictionary dictionary];
        //虚拟哨兵头尾
        _head = [[LRUWeightedNode alloc] init];
        _tail = [[LRUWeightedNode alloc] init];
        _head.next = _tail;
        _tail.prev = _head;
    }
    return self;
}

#pragma mark - 链表底层操作
- (void)addNodeToHead:(LRUWeightedNode *)node {
    node.next = self.head.next;
    node.prev = self.head;
    self.head.next.prev = node;
    self.head.next = node;
}

- (void)removeNode:(LRUWeightedNode *)node {
    LRUWeightedNode *pre = node.prev;
    LRUWeightedNode *nxt = node.next;
    pre.next = nxt;
    nxt.prev = pre;
}

/// 命中后移动到头部，刷新访问时间
- (void)moveNodeToHead:(LRUWeightedNode *)node {
    node.lastAccessTs = [[NSDate date] timeIntervalSince1970];
    [self removeNode:node];
    [self addNodeToHead:node];
}

#pragma mark 【核心加权淘汰逻辑】循环驱逐，直到总权重低于上限
- (void)evictIfNeed {
    while (self.currentTotalWeight > self.maxTotalWeight) {
        LRUWeightedNode *victim = self.tail.prev;
        if (victim == self.head) {
            break; //空链表
        }
        // 删除淘汰节点
        [self removeNode:victim];
        [self.hashMap removeObjectForKey:victim.key];
        self.currentTotalWeight -= victim.weight;
    }
}

#pragma mark Public
- (id)objectForKey:(id)key {
    if (!key) return nil;
    LRUWeightedNode *node = self.hashMap[key];
    if (!node) return nil;
    //命中更新热度，移到链表头部
    [self moveNodeToHead:node];
    return node.value;
}

- (void)setObject:(id)obj forKey:(id)key weight:(NSUInteger)weight {
    if (!key || !obj) return;

    LRUWeightedNode *existNode = self.hashMap[key];
    if (existNode) {
        //key已存在：扣除旧权重，更新value、weight、时间，挪到头部
        self.currentTotalWeight -= existNode.weight;
        existNode.value = obj;
        existNode.weight = weight;
        existNode.lastAccessTs = [[NSDate date] timeIntervalSince1970];
        [self moveNodeToHead:existNode];
        self.currentTotalWeight += weight;
        [self evictIfNeed];
        return;
    }

    if(weight > self.maxTotalWeight){
        return; //不缓存过大对象
    }
    
    //新建节点
    LRUWeightedNode *newNode = [[LRUWeightedNode alloc] initWithKey:key value:obj weight:weight];
    self.hashMap[key] = newNode;
    [self addNodeToHead:newNode];
    self.currentTotalWeight += weight;

    // 触发淘汰
    [self evictIfNeed];
}

- (void)removeObjectForKey:(id)key {
    if (!key) return;
    LRUWeightedNode *node = self.hashMap[key];
    if (!node) return;

    [self removeNode:node];
    [self.hashMap removeObjectForKey:key];
    self.currentTotalWeight -= node.weight;
}

- (void)removeAllObjects {
    [self.hashMap removeAllObjects];
    self.head.next = self.tail;
    self.tail.prev = self.head;
    self.currentTotalWeight = 0;
}

- (NSInteger)cacheItemCount {
    return self.hashMap.count;
}

@end

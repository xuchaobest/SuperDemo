//
//  LRUWeightedNode.m
//  demo
//
//  Created by RichardX on 2026/8/11.
//

#import "LRUWeightedNode.h"

@implementation LRUWeightedNode

- (instancetype)initWithKey:(id)key value:(id)value weight:(NSUInteger)weight {
    self = [super init];
    if (self) {
        _key = [key copy];
        _value = value;
        _weight = weight;
        _lastAccessTs = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

@end

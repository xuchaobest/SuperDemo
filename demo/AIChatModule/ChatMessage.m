//
//  ChatMessage.m
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import "ChatMessage.h"
#import <os/lock.h>

@interface ChatMessage()

@property (nonatomic, assign) os_unfair_lock contentLock;

@end

@implementation ChatMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        _contentLock = OS_UNFAIR_LOCK_INIT;
        _fullContent = @"";
        _deltaContent = @"";
        _aiStatus = AIMessageStatusPending;
    }
    return self;
}

- (void)appendDeltaContent:(NSString *)delta {
    if (!delta || delta.length == 0) return;
    
    os_unfair_lock_lock(&_contentLock);
    self.fullContent = [self.fullContent stringByAppendingString:delta];
    self.deltaContent = delta;
    os_unfair_lock_unlock(&_contentLock);
}

@end

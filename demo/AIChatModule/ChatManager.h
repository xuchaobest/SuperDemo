//
//  ChatManager.h
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import <Foundation/Foundation.h>
#import "ChatMessage.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ChatMessageUpdateBlock)(ChatMessage *msg);

@interface ChatManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, copy, readonly) NSString *currentSessionId;
@property (nonatomic, strong, readonly) NSMutableArray<ChatMessage *> *messageList;

/// 开启一轮新对话
- (void)startNewSession;

/// 发送用户文本消息，发起AI流式请求
- (void)sendUserMessage:(NSString *)text
              onMessage:(ChatMessageUpdateBlock)updateCallback;

/// 主动关闭长连接
- (void)closeStreamConnection;

@end

NS_ASSUME_NONNULL_END

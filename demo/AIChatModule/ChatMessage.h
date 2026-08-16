//
//  ChatMessage.h
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ChatMessageSenderType) {
    ChatMessageSenderUser,     // 用户发送消息
    ChatMessageSenderAI        // AI回复消息
};

// AI消息生命周期状态（流式核心）
typedef NS_ENUM(NSInteger, AIMessageStatus) {
    AIMessageStatusPending,    // 等待开始推送
    AIMessageStatusStreaming,  // 正在流式分片返回
    AIMessageStatusFinished,   // 流式输出完成
    AIMessageStatusError       // 请求失败/断流异常
};

@interface ChatMessage : NSObject

@property (nonatomic, copy) NSString *messageId;       // 唯一ID，幂等关键
@property (nonatomic, copy) NSString *sessionId;       // 会话ID，一次对话全程不变
@property (nonatomic, assign) ChatMessageSenderType senderType;
@property (nonatomic, assign) AIMessageStatus aiStatus;

@property (nonatomic, copy) NSString *fullContent;     // 完整最终文本
@property (nonatomic, copy) NSString *deltaContent;    // 本次增量分片文本（SSE每次推送片段）

@property (nonatomic, assign) NSTimeInterval timestamp;

/// 拼接增量文本（线程安全）
- (void)appendDeltaContent:(NSString *)delta;

@end

NS_ASSUME_NONNULL_END

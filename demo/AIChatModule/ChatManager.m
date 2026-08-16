//
//  ChatManager.m
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import "ChatManager.h"
#import <UIKit/UIKit.h>
#import "ChatDBManager.h"

static NSTimeInterval const kRetryBaseDelay = 1.0;
static NSInteger const kMaxRetryCount = 5;

@interface ChatManager () <NSURLSessionDataDelegate>

@property (nonatomic, copy) NSString *currentSessionId;
@property (nonatomic, strong) NSMutableArray<ChatMessage *> *messageList;

@property (nonatomic, strong) NSURLSession *sseSession;
@property (nonatomic, strong) NSURLSessionDataTask *streamTask;

@property (nonatomic, weak) ChatMessage *activeAIMessage;
@property (nonatomic, copy) ChatMessageUpdateBlock updateCallback;

@property (nonatomic, assign) NSInteger retryCount;
@property (nonatomic, assign) BOOL isReconnecting;

@end

@implementation ChatManager

+ (instancetype)sharedManager {
    static ChatManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _messageList = [NSMutableArray array];
        
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        cfg.timeoutIntervalForRequest = 30;
        _sseSession = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:nil];
        
        // 监听前后台，后台可选择断开，前台尝试重连
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)startNewSession {
    [self closeStreamConnection];
    _currentSessionId = [[NSUUID UUID] UUIDString];
    [self.messageList removeAllObjects];
    self.retryCount = 0;
    // 加载本地历史消息
    NSArray *history = [[ChatDBManager sharedManager] fetchMessageListBySessionId:_currentSessionId];
    [self.messageList setArray:history];
}

- (void)sendUserMessage:(NSString *)text onMessage:(ChatMessageUpdateBlock)updateCallback {
    self.updateCallback = updateCallback;
    // 1.构造用户消息
    ChatMessage *userMsg = [[ChatMessage alloc] init];
    userMsg.messageId = [[NSUUID UUID] UUIDString];
    userMsg.sessionId = self.currentSessionId;
    userMsg.senderType = ChatMessageSenderUser;
    userMsg.fullContent = text;
    userMsg.timestamp = [[NSDate date] timeIntervalSince1970];
    [self.messageList addObject:userMsg];
    
    // 2.构造AI占位消息
    ChatMessage *aiMsg = [[ChatMessage alloc] init];
    aiMsg.messageId = [[NSUUID UUID] UUIDString];
    aiMsg.sessionId = self.currentSessionId;
    aiMsg.senderType = ChatMessageSenderAI;
    aiMsg.aiStatus = AIMessageStatusPending;
    aiMsg.timestamp = [[NSDate date] timeIntervalSince1970];
    [self.messageList addObject:aiMsg];
    self.activeAIMessage = aiMsg;
    
    // UI刷新新增两条消息
    if (updateCallback) updateCallback(aiMsg);
    // 每次增量更新 / 状态完成，落盘
    [[ChatDBManager sharedManager] insertOrUpdateMessage:self.activeAIMessage];
    
    // 发起SSE长连接
    [self createSSEStreamRequestWithText:text];
}

- (void)createSSEStreamRequestWithText:(NSString *)text {
    [self closeStreamConnection];
    
    NSURL *url = [NSURL URLWithString:@"https://xxx.xxx/stream/chat"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
    [req setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    
    NSDictionary *body = @{
        @"sessionId": self.currentSessionId,
        @"query": text
    };
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    
    self.streamTask = [self.sseSession dataTaskWithRequest:req];
    [self.streamTask resume];
    self.activeAIMessage.aiStatus = AIMessageStatusStreaming;
}

#pragma mark - SSE Delegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (!data.length || !self.activeAIMessage) return;
    NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // SSE标准格式解析 data: xxx\n\n
    NSArray *events = [raw componentsSeparatedByString:@"\n\n"];
    for (NSString *eventStr in events) {
        if (![eventStr hasPrefix:@"data:"]) continue;
        NSString *delta = [eventStr stringByReplacingOccurrencesOfString:@"data:" withString:@""];
        delta = [delta stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (delta.length == 0) continue;
        
        // 原子追加文本
        [self.activeAIMessage appendDeltaContent:delta];
        // 回调UI局部刷新
        if (self.updateCallback) {
            self.updateCallback(self.activeAIMessage);
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!self.activeAIMessage) return;
    
    if (error) {
        // 网络异常，尝试重连（指数退避）
        self.activeAIMessage.aiStatus = AIMessageStatusError;
        if (self.retryCount < kMaxRetryCount && !self.isReconnecting) {
            self.isReconnecting = YES;
            NSTimeInterval delay = kRetryBaseDelay * pow(2, self.retryCount);
            self.retryCount++;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
                self.isReconnecting = NO;
                // 重连恢复流式会话（携带sessionId续传，业务后端支持断点续传）
                [self createSSEStreamRequestWithText:@""];
            });
        }
    } else {
        // 正常结束
        self.activeAIMessage.aiStatus = AIMessageStatusFinished;
    }
    if (self.updateCallback) self.updateCallback(self.activeAIMessage);
    // 持久化
    [[ChatDBManager sharedManager] insertOrUpdateMessage:self.activeAIMessage];
}

- (void)closeStreamConnection {
    if (self.streamTask) {
        [self.streamTask cancel];
        self.streamTask = nil;
    }
}

- (void)appBecomeActive {
    // APP前台激活，如果AI消息处于异常状态，尝试恢复
    if (self.activeAIMessage.aiStatus == AIMessageStatusError && self.retryCount < kMaxRetryCount) {
        [self createSSEStreamRequestWithText:@""];
    }
}
@end

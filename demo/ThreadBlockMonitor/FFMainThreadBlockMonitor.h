//
//  FFMainThreadBlockMonitor.h
//  demo
//
//  Created by RichardX on 2026/8/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FFBlockMonitorConfig : NSObject

/// 主线程卡顿阈值，单位毫秒，默认 400ms
@property (nonatomic, assign) NSUInteger mainThreadBlockThresholdMs;
/// 子线程任务超时阈值，单位毫秒，默认800ms
@property (nonatomic, assign) NSUInteger childThreadTimeoutThresholdMs;
/// 是否捕获堆栈（⚠️Release环境强制失效，仅Debug生效）
@property (nonatomic, assign) BOOL enableCaptureStack;

@end


typedef void(^FFBlockMonitorCallback)(BOOL isMainThread, NSString *stackInfo, NSTimeInterval blockTime);

@interface FFMainThreadBlockMonitor : NSObject

@property(nonatomic,readonly) FFBlockMonitorConfig *config;

+ (instancetype)sharedMonitor;

- (void)startMonitorWithConfig:(FFBlockMonitorConfig *)config callback:(FFBlockMonitorCallback)callback;

- (void)stopMonitor;

/// 标记子线程任务开始（需要监控的耗时任务调用）
- (void)markChildTaskStart:(NSString *)taskTag;
/// 标记子线程任务结束
- (void)markChildTaskEnd:(NSString *)taskTag;

@end

NS_ASSUME_NONNULL_END

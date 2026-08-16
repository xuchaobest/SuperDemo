//
//  FFMainThreadBlockMonitor.m
//  demo
//
//  Created by RichardX on 2026/8/4.
//

#import "FFMainThreadBlockMonitor.h"
#import <pthread.h>
#import <execinfo.h>
#import <mach/mach_time.h>

// 宏：Release下强制关闭堆栈采集，规避私有API风险
#if DEBUG
#define FF_MONITOR_CAPTURE_STACK_AVAILABLE 1
#else
#define FF_MONITOR_CAPTURE_STACK_AVAILABLE 0
#endif

@interface FFBlockMonitorConfig()
@end

@implementation FFBlockMonitorConfig
- (instancetype)init {
    self = [super init];
    if(self) {
        _mainThreadBlockThresholdMs = 400;
        _childThreadTimeoutThresholdMs = 800;
        _enableCaptureStack = YES;
    }
    return self;
}
@end


@interface FFMainThreadBlockMonitor()

@property(nonatomic,strong) FFBlockMonitorConfig *config;
@property(nonatomic,copy) FFBlockMonitorCallback callback;

@property(nonatomic,assign) CFRunLoopObserverRef mainRunloopObserver;
@property(nonatomic,strong) dispatch_semaphore_t mainLoopSemaphore;

///子线程监控任务记录表
@property(nonatomic,strong) NSMutableDictionary<NSString *,NSNumber *> *childTaskDict;
@property(nonatomic,strong) dispatch_queue_t childMonitorQueue;
@property(nonatomic,assign) BOOL isRunning;

@end

@implementation FFMainThreadBlockMonitor

+ (instancetype)sharedMonitor {
    static FFMainThreadBlockMonitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if(self) {
        _childTaskDict = [NSMutableDictionary dictionary];
        _childMonitorQueue = dispatch_queue_create("com.ff.blockmonitor.child", DISPATCH_QUEUE_SERIAL);
        _mainLoopSemaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)dealloc {
    // 对象销毁也要清理RunloopObserver，避免对象释放，但RunLoop还在回调已销毁的monitor
    if (_mainRunloopObserver) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _mainRunloopObserver, kCFRunLoopCommonModes);
        CFRelease(_mainRunloopObserver);
        _mainRunloopObserver = NULL;
    }
}

- (void)startMonitorWithConfig:(FFBlockMonitorConfig *)config callback:(FFBlockMonitorCallback)callback {
    if (_isRunning) return;
    _isRunning = YES;
    self.config = config;
    self.callback = callback;
    [self startMainThreadMonitor];
//    [self startChildThreadMonitor];
}

- (void)stopMonitor {
    if (!_isRunning) return;
    _isRunning = NO;

    if (_mainRunloopObserver) {
        //第一步：从RunLoop移除，RunLoop内部release一次
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _mainRunloopObserver, kCFRunLoopCommonModes);
        //第二步：释放create带来的引用计数
        CFRelease(_mainRunloopObserver);
        // ✅非常关键：指针置空，消除野指针！
        _mainRunloopObserver = NULL;
    }

    dispatch_sync(self.childMonitorQueue, ^{
        [self.childTaskDict removeAllObjects];
    });
}

#pragma mark - 主线程Runloop卡顿监控
static void FFRunloopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    FFMainThreadBlockMonitor *monitor = (__bridge FFMainThreadBlockMonitor*)info;
    if(activity & kCFRunLoopBeforeSources || activity & kCFRunLoopAfterWaiting) {
        dispatch_async(monitor.childMonitorQueue, ^{
            uint64_t begin = mach_absolute_time();
            long ret = dispatch_semaphore_wait(monitor.mainLoopSemaphore, dispatch_time(DISPATCH_TIME_NOW, monitor.config.mainThreadBlockThresholdMs * NSEC_PER_MSEC));
            if(ret != 0) {
                NSString *stack = nil;
#if FF_MONITOR_CAPTURE_STACK_AVAILABLE
                if(monitor.config.enableCaptureStack) {
                    // 限制：无法抓取主线程堆栈！因为当前执行在监控子线程
                    // 【重点】上架版不能用 backtrace_thread 私有接口
                    stack = @"[Release:skip thread stack capture]";
                }
#endif
                uint64_t costNs = mach_absolute_time() - begin;
                NSTimeInterval costMs = (double)costNs / NSEC_PER_MSEC;
                if(monitor.callback) {
                    monitor.callback(YES, stack, costMs);
                }
            }
            dispatch_semaphore_signal(monitor.mainLoopSemaphore);
        });
    }
}

- (void)startMainThreadMonitor {
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    _mainRunloopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                                    kCFRunLoopBeforeSources | kCFRunLoopAfterWaiting,
                                                    YES,
                                                    0,
                                                    FFRunloopObserverCallBack,
                                                    &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _mainRunloopObserver, kCFRunLoopCommonModes);
}

#pragma mark - 子线程超时监控
- (void)markChildTaskStart:(NSString *)taskTag {
    if(!taskTag || !_isRunning) return;
    NSTimeInterval ts = [[NSDate date] timeIntervalSince1970] * 1000;
    dispatch_async(self.childMonitorQueue, ^{
        self.childTaskDict[taskTag] = @(ts);
    });
}

- (void)markChildTaskEnd:(NSString *)taskTag {
    if(!taskTag) return;
    dispatch_async(self.childMonitorQueue, ^{
        [self.childTaskDict removeObjectForKey:taskTag];
    });
}

- (void)startChildThreadMonitor {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.childMonitorQueue, ^{
        while (weakSelf && weakSelf.isRunning) {
            [weakSelf checkChildTaskTimeout];
            [NSThread sleepForTimeInterval:0.1];
        }
    });
}

- (void)checkChildTaskTimeout {
    NSTimeInterval nowMs = [[NSDate date] timeIntervalSince1970] * 1000;
    NSDictionary *snapshot = [self.childTaskDict copy];
    for (NSString *tag in snapshot.allKeys) {
        NSTimeInterval startMs = [snapshot[tag] doubleValue];
        NSTimeInterval cost = nowMs - startMs;
        if(cost >= self.config.childThreadTimeoutThresholdMs) {
            NSString *stack = nil;
#if FF_MONITOR_CAPTURE_STACK_AVAILABLE
            if(self.config.enableCaptureStack) {
                stack = [self captureCurrentThreadStack];
            }
#else
            stack = @"[Release:skip stack]";
#endif
            if(self.callback) {
                NSString *msg = [NSString stringWithFormat:@"taskTag:%@ | %@", tag, stack?:@""];
                self.callback(NO, msg, cost);
            }
            dispatch_async(self.childMonitorQueue, ^{
                [self.childTaskDict removeObjectForKey:tag];
            });
        }
    }
}

#pragma mark - 仅捕获【当前执行线程】堆栈，无私有API
- (NSString *)captureCurrentThreadStack {
    NSMutableString *result = [NSMutableString string];
    void *backtraceBuffer[128];
    int count = backtrace(backtraceBuffer, 128);
    if(count <= 0) {
        return @"no stack";
    }
    char **symbols = backtrace_symbols(backtraceBuffer, count);
    for(int i = 0; i < count; i++) {
        [result appendFormat:@"%s\n", symbols[i]];
    }
    free(symbols);
    return result;
}

@end

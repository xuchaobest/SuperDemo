//
//  ViewController.m
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import "ViewController.h"
#import "CycleMenuView.h"
#import "ImageTableViewCell.h"
#import "ImageCacheManager.h"
#import "FFMainThreadBlockMonitor.h"
#import "demo-Swift.h"

static NSString * const kCellIdentifier = @"ImageCell";

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
/// 图片 URL 数据源
@property (nonatomic, strong) NSArray<NSString *> *imageURLs;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    NSInteger len = [self lengthOfLongestSubstring:@"abcabcbb"];
    NSLog(@">>>%ld", len); // 输出3
    
    UIEdgeInsets insets = [self getWindowSafeAreaInset];
    CycleMenuView *cycle = [[CycleMenuView alloc] initWithFrame:CGRectMake(0, 60, self.view.bounds.size.width / 2, self.view.bounds.size.width / 2)];
    cycle.clickItemBlock = ^(NSString * str) {
        [self simulateMainThreadBlock];
//        [self simulateChildLongTask];
        if ([str isEqualToString:@"我的"]) {
            [self pushToDeepseekChatVC];
        } else if ([str isEqualToString:@"设置"]) {
            [self pushToSwiftUIVC];
        } else {
            
        }
        
        
    };
    [self.view addSubview:cycle];
    
    // 准备测试数据（实际项目中可从网络或本地获取）
    [self loadTableViewTestData];
    
    [self setupBlockMonitor];
}

- (void)viewDidAppear:(BOOL)animated {
    [self showMetalCircleAniView];
}

- (NSInteger)lengthOfLongestSubstring:(NSString *)s {
    // key:单个字符字符串, value:字符最近下标 NSNumber
    NSMutableDictionary<NSString *, NSNumber *> *charIndex = [NSMutableDictionary dictionary];
    NSInteger left = 0;
    NSInteger maxLen = 0;
    
    NSUInteger strLen = s.length;
    for (NSInteger right = 0; right < strLen; right++) {
        unichar c = [s characterAtIndex:right];
        NSString *key = [NSString stringWithCharacters:&c length:1];
        
        NSNumber *idxNum = charIndex[key];
        if (idxNum) {
            NSInteger idx = idxNum.integerValue;
            if (idx >= left) {
                left = idx + 1;
            }
        }
        
        charIndex[key] = @(right);
        NSInteger currentLen = right - left + 1;
        if (currentLen > maxLen) {
            maxLen = currentLen;
        }
    }
    return maxLen;
}

- (void)loadTableViewTestData {
    // 模拟 20 张网络图片 URL（可使用公开的图片占位服务）
    NSMutableArray *urls = [NSMutableArray array];
    for (int i = 1; i <= 20; i++) {
        // 示例：使用 picsum.photos 提供的随机图片（宽度 300，高度 200）
        NSString *url = [NSString stringWithFormat:@"https://picsum.photos/seed/%d/300/200", i];
        [urls addObject:url];
    }
    self.imageURLs = [urls copy];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.imageURLs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    // 获取当前行对应的图片 URL
    NSString *urlString = self.imageURLs[indexPath.row];
    // 配置 Cell（内部会自动处理缓存、下载及复用防错乱）
    [cell configureWithURLString:urlString];
    
    return cell;
}

#pragma mark - UITableViewDelegate（可选）

// 如果需要在滚动停止时才加载图片以提升性能，可在此实现懒加载策略
// 但本例中 Cell 的 configure 方法内部已有防错乱和复用取消机制，无须额外处理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // 点击可做预览或其他操作
    NSLog(@"选中第 %ld 行", (long)indexPath.row);
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetWidth(self.view.bounds) / 2 + 20, CGRectGetWidth(self.view.bounds), 300) style:UITableViewStylePlain];
        [_tableView registerClass:[ImageTableViewCell class] forCellReuseIdentifier:kCellIdentifier];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 200;
        _tableView.rowHeight = UITableViewAutomaticDimension;
    }
    return _tableView;
}

#pragma mark - 线程卡顿监测
- (void)setupBlockMonitor {
    FFBlockMonitorConfig *cfg = [[FFBlockMonitorConfig alloc] init];
    cfg.mainThreadBlockThresholdMs = 350;
    cfg.childThreadTimeoutThresholdMs = 700;
    cfg.enableCaptureStack = YES;
    
    [[FFMainThreadBlockMonitor sharedMonitor] startMonitorWithConfig:cfg callback:^(BOOL isMainThread, NSString *stackInfo, NSTimeInterval blockTime) {
        if(isMainThread) {
            NSLog(@"🔥主线程卡顿 time=%.0f ms \n%@",blockTime,stackInfo);
        }else{
            NSLog(@"⚠️子线程超时 time=%.0f ms \n%@",blockTime,stackInfo);
        }
    }];
}

//模拟主线程卡顿
- (void)simulateMainThreadBlock {
    //子线程持有信号量，主线程wait，制造主线程锁等待卡顿
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);
        dispatch_semaphore_signal(sem);
    });

    //写在主线程，主线程阻塞1s，runloop卡顿检测可以捕获
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

- (void)test {
    NSArray *arr = @[@{@"a" : @"aa", @"b" : @"bb"}, @{@"a" : @"aaa", @"b" : @"bbb"}];
    NSMutableArray *marr = [[NSMutableArray alloc] initWithCapacity:arr.count];
    NSMutableDictionary *mdic = @{}.mutableCopy;
    for (NSDictionary *dic in arr) {
        NSString *a = dic[@"a"];
        NSString *b = dic[@"b"];
        [mdic setObject:a forKey:@"a"];
        [mdic setObject:b forKey:@"b"];
        [marr addObject:mdic.copy];
    }
    for (NSDictionary *dic in arr) {
        @autoreleasepool {
            NSString *a = dic[@"a"];
            NSString *b = dic[@"b"];
            [mdic setObject:a forKey:@"a"];
            [mdic setObject:b forKey:@"b"];
            [marr addObject:mdic.copy];
        }
    }
    for (NSDictionary *dic in arr) {
        const char *a = [dic[@"a"] UTF8String];
        const char *b = [dic[@"b"] UTF8String];
        [mdic setObject:[NSString stringWithUTF8String:a] forKey:@"a"];
        [mdic setObject:[NSString stringWithUTF8String:a] forKey:@"b"];
        [marr addObject:mdic.mutableCopy];
    }
}

//模拟子线程耗时任务
- (void)simulateChildLongTask {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [[FFMainThreadBlockMonitor sharedMonitor] markChildTaskStart:@"test_network_task"];
        sleep(1);
        [[FFMainThreadBlockMonitor sharedMonitor] markChildTaskEnd:@"test_network_task"];
    });
}

- (void)pushToDeepseekChatVC {
    ChatViewController *chatVC = [[ChatViewController alloc] init];
    [self.navigationController pushViewController:chatVC animated:YES];
}

- (void)pushToSwiftUIVC {
    TaskFlowVC *vc = [TaskFlowVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showMetalCircleAniView {
    // 1. 创建背景容器
    UIView *containerView = [[UIView alloc] init];
    containerView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    containerView.layer.cornerRadius = 16;
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:containerView];
    
    // 2. 配置 MTKView
    MTKView *mtkView = [[MTKView alloc] init];
    mtkView.translatesAutoresizingMaskIntoConstraints = NO;
    mtkView.paused = NO;
    mtkView.enableSetNeedsDisplay = NO;
    [containerView addSubview:mtkView];
    
    // 3. 绑定 Metal 渲染器 (Swift类)
    MetalCircleRenderer *renderer = [[MetalCircleRenderer alloc] initWithMtkView:mtkView];
    NSAssert(renderer != nil, @"Metal 初始化失败，请检查设备或 Metal 文件配置");
    
    // 绑定生命周期
    static char rendererAssociatedKey;
    objc_setAssociatedObject(mtkView, &rendererAssociatedKey, renderer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // 4. 布局约束
        [NSLayoutConstraint activateConstraints:@[
            [containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
            [containerView.widthAnchor constraintEqualToConstant:120.0],
            [containerView.heightAnchor constraintEqualToConstant:120.0],
            
            [mtkView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
            [mtkView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],
            [mtkView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
            [mtkView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor]
        ]];
}

- (UIEdgeInsets)getWindowSafeAreaInset {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    // 1. 获取所有连接中的场景
    NSSet<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes;
    UIWindowScene *foregroundActiveScene = nil;
    // 2. 优先寻找前台活跃的 WindowScene（当前用户正在交互的）
    for (UIWindowScene *scene in scenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            foregroundActiveScene = scene;
            break;
        }
    }
    // 3. 如果没找到活跃的，退而求其次找前台非活跃的（例如下拉通知栏时）
    if (!foregroundActiveScene) {
        for (UIWindowScene *scene in scenes) {
            if (scene.activationState == UISceneActivationStateForegroundInactive) {
                foregroundActiveScene = scene;
                break;
            }
        }
    }
    // 4. 通过场景拿到窗口（这里不使用 UIApplication.windows，而是用 scene.windows）
    UIWindow *targetWindow = foregroundActiveScene.windows.firstObject;
    // 更好的做法：在场景的窗口中找到真正的 keyWindow
    for (UIWindow *window in foregroundActiveScene.windows) {
        if (window.isKeyWindow) {
            targetWindow = window;
            break;
        }
    }
    insets = targetWindow.safeAreaInsets;
    return insets;
}

@end

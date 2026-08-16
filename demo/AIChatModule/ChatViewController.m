//
//  ChatViewController.m
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import "ChatViewController.h"
#import "ChatManager.h"
#import "ChatMessage.h"
#import "ChatCell.h"

static NSString *const chatCell = @"ChatCell";

@interface ChatViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *cellHeightCache;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cellHeightCache = [NSMutableDictionary dictionary];
    [self setupCollectionView];
    [[ChatManager sharedManager] startNewSession];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[ChatManager sharedManager] closeStreamConnection];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 12;
    layout.estimatedItemSize = CGSizeMake(self.view.bounds.size.width, 50);
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    // 注册cell ...
}

/// 发送消息入口
- (void)sendText:(NSString *)text {
    __weak typeof(self) weakSelf = self;
    [[ChatManager sharedManager] sendUserMessage:text onMessage:^(ChatMessage *msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf refreshMessage:msg];
        });
    }];
}

/// 【核心】增量更新，局部刷新，禁止reloadData
- (void)refreshMessage:(ChatMessage *)targetMsg {
    NSArray *msgList = [ChatManager sharedManager].messageList;
    NSInteger index = -1;
    for (NSInteger i = 0; i < msgList.count; i++) {
        ChatMessage *m = msgList[i];
        if ([m.messageId isEqualToString:targetMsg.messageId]) {
            index = i;
            break;
        }
    }
    if (index < 0) return;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    // 清除高度缓存，重新计算高度
    [self.cellHeightCache removeObjectForKey:targetMsg.messageId];
    
    // 局部刷新单个cell
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    
    // 自动滚动到底部
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    });
}

#pragma mark UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [ChatManager sharedManager].messageList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ChatMessage *msg = [ChatManager sharedManager].messageList[indexPath.item];
    ChatCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:chatCell forIndexPath:indexPath];
    [cell configWithMessage:msg];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    ChatMessage *msg = [ChatManager sharedManager].messageList[indexPath.item];
    // 命中缓存直接返回
    if (self.cellHeightCache[msg.messageId]) {
        CGFloat h = self.cellHeightCache[msg.messageId].floatValue;
        return CGSizeMake(collectionView.bounds.size.width, h);
    }
    // 文本动态高度计算
    CGFloat height = [self calculateTextHeight:msg.fullContent];
    self.cellHeightCache[msg.messageId] = @(height);
    return CGSizeMake(collectionView.bounds.size.width, height);
}

- (CGFloat)calculateTextHeight:(NSString *)text {
    // 文本宽高计算实现
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat maxWidth = self.view.bounds.size.width - 80;
    CGSize size = [text boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
    return size.height + 30;
}

@end

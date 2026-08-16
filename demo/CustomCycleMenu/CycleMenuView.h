//
//  CycleMenuView.h
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CycleMenuView : UIView

@property (nonatomic, copy) void(^clickItemBlock)(NSString *);
/// 初始化菜单数据，每个元素为 (标题, 颜色)
- (void)setupWithSectors:(NSArray<NSDictionary<NSString *, id> *> *)sectorData;

@end

NS_ASSUME_NONNULL_END

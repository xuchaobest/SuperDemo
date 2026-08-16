//
//  CycleMenuView.m
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import "CycleMenuView.h"
#import <objc/runtime.h>

@interface CycleMenuView ()

@property (nonatomic, strong) NSArray<NSDictionary<NSString *, id> *> *sectors;
@property (nonatomic, strong) NSArray<NSNumber *> *sectorAngles; // 存储每个扇区的起始角度
@property (nonatomic, assign) CGFloat rotationAngle; // 整体旋转角度

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;



@end

@implementation CycleMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.multipleTouchEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    
    // 手势
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:self.panGesture];
    [self addGestureRecognizer:self.tapGesture];
    // 点击手势等待拖拽失败
    [self.tapGesture requireGestureRecognizerToFail:self.panGesture];
    
    // 默认数据（可后续通过 setup 修改）
    [self setupWithSectors:@[
        @{@"title": @"首页", @"color": [UIColor systemRedColor]},
        @{@"title": @"发现", @"color": [UIColor systemBlueColor]},
        @{@"title": @"消息", @"color": [UIColor systemGreenColor]},
        @{@"title": @"我的", @"color": [UIColor systemOrangeColor]},
        @{@"title": @"设置", @"color": [UIColor systemPurpleColor]}
    ]];
}

- (void)setupWithSectors:(NSArray<NSDictionary<NSString *,id> *> *)sectorData {
    if (!sectorData.count) {
        return;
    }
    
    self.sectors = sectorData;
    NSMutableArray *angles = [NSMutableArray array];
    CGFloat sectorAngle = 2 * M_PI / sectorData.count;
    for (NSInteger i = 0; i < sectorData.count; i++) {
        [angles addObject:@(i * sectorAngle)];
    }
    self.sectorAngles = [angles copy];
    self.rotationAngle = 0;
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return;
    
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) / 2 - 20;
    CGFloat sectorAngle = 2 * M_PI / self.sectors.count;
    
    for (NSInteger i = 0; i < self.sectors.count; i++) {
        NSDictionary *sector = self.sectors[i];
        UIColor *color = sector[@"color"];
        CGFloat startAngle = [self.sectorAngles[i] floatValue] + self.rotationAngle;
        CGFloat endAngle = startAngle + sectorAngle;
        
        // 绘制扇形
        CGContextMoveToPoint(context, center.x, center.y);
        CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillPath(context);
        
        // 绘制分割线
        CGContextMoveToPoint(context, center.x, center.y);
        CGContextAddLineToPoint(context, center.x + radius * cos(startAngle),
                                center.y + radius * sin(startAngle));
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetLineWidth(context, 2);
        CGContextStrokePath(context);
    }
    
    // 绘制中心圆
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center radius:30 startAngle:0 endAngle:2*M_PI clockwise:YES];
    [[UIColor whiteColor] setFill];
    [circlePath fill];
}

#pragma mark - Gesture Handlers

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGPoint touchPoint = [gesture locationInView:self];
    CGFloat deltaX = touchPoint.x - center.x;
    CGFloat deltaY = touchPoint.y - center.y;
    CGFloat currentAngle = atan2(deltaY, deltaX);
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // 存储初始角度（使用关联对象或实例变量）
        objc_setAssociatedObject(gesture, "_lastAngle", @(currentAngle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        NSNumber *lastAngleNum = objc_getAssociatedObject(gesture, "_lastAngle");
        CGFloat lastAngle = lastAngleNum ? [lastAngleNum floatValue] : 0;
        CGFloat deltaAngle = currentAngle - lastAngle;
        self.rotationAngle += deltaAngle;
        objc_setAssociatedObject(gesture, "_lastAngle", @(currentAngle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self setNeedsDisplay];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    CGPoint touchPoint = [gesture locationInView:self];
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat deltaX = touchPoint.x - center.x;
    CGFloat deltaY = touchPoint.y - center.y;
    CGFloat angle = atan2(deltaY, deltaX);
    
    // 归一化到 0 ~ 2π
    CGFloat normalized = angle < 0 ? angle + 2 * M_PI : angle;
    normalized = fmod(normalized - self.rotationAngle, 2 * M_PI);
    if (normalized < 0) normalized += 2 * M_PI;
    
    CGFloat sectorAngle = 2 * M_PI / self.sectors.count;
    NSInteger index = (NSInteger)(normalized / sectorAngle);
    if (index < self.sectors.count) {
        NSDictionary *sector = self.sectors[index];
        NSLog(@"点击了扇区: %@", sector[@"title"]);
        // 这里可添加选中动画等
        self.clickItemBlock ? self.clickItemBlock(sector[@"title"]) : nil;
    }
}

#pragma mark - Hit Testing (事件穿透)

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) / 2;
    CGFloat distance = sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2));
    if (distance > radius) {
        return nil; // 点击在圆外不响应
    }
    return [super hitTest:point withEvent:event];
}

@end

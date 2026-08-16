//
//  demoTests.m
//  demoTests
//
//  Created by RichardX on 2026/8/12.
//

#import <XCTest/XCTest.h>
#import "CycleMenuView.h"

@interface DemoTests : XCTestCase
@end

@implementation DemoTests

- (void)testCycleMenuView_InitDefault {
    CGRect frame = CGRectMake(0,0,300,300);
    CycleMenuView *menu = [[CycleMenuView alloc] initWithFrame:frame];
    
    XCTAssertNotNil(menu);
    XCTAssertEqual(menu.bounds.size.width, 300);
    XCTAssertEqual(menu.bounds.size.height, 300);
    
    // 校验内部手势是否创建成功
    XCTAssertTrue(menu.gestureRecognizers.count >= 2);
    
    BOOL hasPan = NO;
    BOOL hasTap = NO;
    for (UIGestureRecognizer *g in menu.gestureRecognizers) {
        if ([g isKindOfClass:[UIPanGestureRecognizer class]]) hasPan = YES;
        if ([g isKindOfClass:[UITapGestureRecognizer class]]) hasTap = YES;
    }
    XCTAssertTrue(hasPan,@"Pan手势必须存在");
    XCTAssertTrue(hasTap,@"Tap手势必须存在");
}

/// 测试setupWithSectors正常赋值
- (void)testCycleMenuView_SetupNormalData {
    CycleMenuView *menu = [[CycleMenuView alloc] initWithFrame:CGRectMake(0,0,200,200)];
    
    NSArray *testData = @[
        @{@"title":@"A", @"color":[UIColor redColor]},
        @{@"title":@"B", @"color":[UIColor blueColor]}
    ];
    [menu setupWithSectors:testData];
    
    // KVC读取私有成员变量（单元测试常用手段，不污染业务头文件）
    NSArray *sectors = [menu valueForKey:@"sectors"];
    NSArray *angles = [menu valueForKey:@"sectorAngles"];
    NSNumber *rotationAngle = [menu valueForKey:@"rotationAngle"];
    
    XCTAssertEqual(sectors.count, 2);
    XCTAssertEqual(angles.count,2);
    XCTAssertEqualWithAccuracy([rotationAngle floatValue], 0.0, 0.0001);
    
    CGFloat perAngle = 2 * M_PI / 2.0;
    CGFloat firstAngle = [angles.firstObject floatValue];
    XCTAssertEqualWithAccuracy(firstAngle, 0, 0.0001);
    XCTAssertEqualWithAccuracy([angles[1] floatValue], perAngle, 0.0001);
}

/// 测试setupWithSectors传入空数组，直接return，不修改内部数据
- (void)testCycleMenuView_SetupEmptyData {
    CycleMenuView *menu = [[CycleMenuView alloc] initWithFrame:CGRectMake(0,0,200,200)];
    NSArray *oldSectors = [menu valueForKey:@"sectors"];
    
    [menu setupWithSectors:@[]];
    NSArray *newSectors = [menu valueForKey:@"sectors"];
    
    // 空数组直接return，内部数据保持不变
    XCTAssertEqualObjects(oldSectors, newSectors);
}

/// 测试点击扇区，clickItemBlock正常回调（模拟tap触发）
- (void)testCycleMenuView_TapItemBlockCallback {
    CycleMenuView *menu = [[CycleMenuView alloc] initWithFrame:CGRectMake(0,0,300,300)];
    
    NSArray *testData = @[
        @{@"title":@"测试1", @"color":[UIColor redColor]},
        @{@"title":@"测试2", @"color":[UIColor blueColor]}
    ];
    [menu setupWithSectors:testData];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"tap block callback"];
    __block NSString *receiveTitle = nil;
    
    menu.clickItemBlock = ^(NSString *title) {
        receiveTitle = title;
        [exp fulfill];
    };
    
    // 直接调用内部tap处理方法，KVC拿到私有handleTap:
    UITapGestureRecognizer *tap = nil;
    for(UIGestureRecognizer *g in menu.gestureRecognizers) {
        if([g isKindOfClass:[UITapGestureRecognizer class]]){
            tap = (UITapGestureRecognizer *)g;
            break;
        }
    }
    XCTAssertNotNil(tap);
    
    // 模拟点击：中心点右侧，角度0，命中第0个扇区
    tap.state = UIGestureRecognizerStateEnded;
    // OC runtime 直接调用selector
    [menu performSelector:@selector(handleTap:) withObject:tap];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqualObjects(receiveTitle, @"测试1");
}

/// 测试hitTest：点击圆外返回nil，圆内返回self
- (void)testCycleMenuView_HitTest {
    CycleMenuView *menu = [[CycleMenuView alloc] initWithFrame:CGRectMake(0,0,200,200)];
    // bounds (0,0,200,200), center (100,100), radius=100
    
    // 1.圆外点 (190, 100) 距离中心90？不，测试圆外：(220,100)，超出view半径
    UIView *outView = [menu hitTest:CGPointMake(220, 100) withEvent:nil];
    XCTAssertNil(outView,@"圆外点击hitTest返回nil");
    
    // 2.圆内点 (110,100)
    UIView *innerView = [menu hitTest:CGPointMake(110, 100) withEvent:nil];
    XCTAssertEqual(innerView, menu,@"圆内点击返回自身");
}

@end

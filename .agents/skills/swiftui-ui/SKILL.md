# SwiftUI UI 开发技能

## 适用场景
- 创建新视图
- 修改现有 UI 布局
- 添加动画效果

## 核心原则
1. **声明式语法**：使用 `@ViewBuilder` 构建视图树。
2. **状态驱动**：UI 完全由状态决定，使用 `@State`、`@Binding`、`@ObservedObject`。
3. **响应式布局**：优先使用 `VStack`/`HStack`/`ZStack` + `Spacer()`，避免硬编码尺寸。

## 代码模板
```swift
import SwiftUI

struct <#Feature#>View: View {
    @StateObject private var viewModel = <#Feature#>ViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.items, id: \.id) { item in
                Text(item.name)
            }
            .navigationTitle("<#Title#>")
            .overlay(Group {
                if viewModel.isLoading { ProgressView() }
            })
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

class <#Feature#>ViewModel: ObservableObject {
    @Published var items: [<#Model#>] = []
    @Published var isLoading = false
    
    func loadData() {
        isLoading = true
        // 调用 Service
        isLoading = false
    }
}

常用修饰符

padding()、background()、cornerRadius() 用于样式。
animation() 用于隐式动画。
transition() 用于视图切换动画。


### 4. 提示模板示例（`.agents/templates/feature_request.md`）

# 新功能开发请求

**功能名称**：<功能描述>
**关联模块**：<iOS/Flutter/Shared>
**优先级**：P0/P1/P2

## 需求描述
<详细描述功能需求>

## 验收标准
- [ ] 标准1
- [ ] 标准2

## 设计稿
- Figma 链接：<链接>
- 交互说明：<说明>

## 技术约束
- 依赖 <库名> 版本 <版本号>
- 需要兼容 <iOS/Android> 最低版本

## 测试要点
- <测试用例1>
- <测试用例2>
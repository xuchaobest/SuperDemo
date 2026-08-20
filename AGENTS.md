# Project: SuperDemo (SwiftUI + Flutter)

## 📌 项目概述
- **技术栈**：
  - iOS 原生：SwiftUI + Combine (iOS 16.6+)
  - 跨平台：Flutter (用于未来大规模跨端功能)
- **混合策略**：核心业务模块（如登录、支付）使用 SwiftUI 开发以保证体验，非核心或通用功能逐步迁移至 Flutter 以实现跨平台复用。
- **状态管理**：原生部分使用 `@StateObject` + `ObservableObject`；Flutter 部分使用 Provider 或 Riverpod（待定）。

## 🧱 架构原则
- **分层设计**：`View` → `ViewModel` → `Service` → `Repository`
- **依赖注入**：优先使用构造器注入，避免硬编码。
- **模块化**：每个功能模块独立成 Swift Package 或 Flutter package，便于复用和测试。

## 📝 编码规范
### SwiftUI
- 使用 `SwiftLint` 强制代码风格（`.swiftlint.yml` 已配置）。
- 视图文件命名：`<Feature>View.swift`，ViewModel 命名：`<Feature>ViewModel.swift`。
- 使用 `@MainActor` 标记 UI 相关函数。
- 避免在 `View` 中直接执行网络请求，统一通过 `ViewModel` 调用 `Service`。

### Flutter
- 使用 `flutter format` 格式化代码。
- Widget 命名：`<Feature>Widget`，业务逻辑放在 `Bloc` 或 `Provider` 中。
- 优先使用 `StatelessWidget`，仅在需要状态管理时使用 `StatefulWidget`。
- 所有 `async` 操作必须处理异常，使用 `try-catch` 或 `Future.catchError`。

### 跨平台交互
- 通过 `MethodChannel` 或 `EventChannel` 通信，所有通道名必须在 `ChannelConstants` 中统一定义。
- 参数序列化统一使用 `JSON`，在 iOS 端使用 `Codable`，在 Flutter 端使用 `json_serializable`。

## 📂 项目结构
项目结构定义
 SuperDemo/
 ├── iOS/ # SwiftUI 原生代码
 │ ├── App/ # App 入口及生命周期
 │ ├── Features/ # 各功能模块
 │ │ ├── Login/
 │ │ ├── Home/
 │ │ └── Profile/
 │ ├── Services/ # 网络、数据库等公共服务
 │ ├── Utils/ # 工具类/扩展
 │ └── Resources/ # 资源文件
 ├── flutter_module/ # Flutter 模块 (作为子模块或 Package)
 │ ├── lib/
 │ │ ├── features/
 │ │ ├── services/
 │ │ └── utils/
 │ └── pubspec.yaml
 └── shared/ # 跨平台共享资源（如 Proto 定义）

 
## 🔧 常用命令
- **iOS**: `xcodebuild -workspace SuperDemo.xcworkspace -scheme SuperDemo`
- **Flutter**: `flutter pub get` / `flutter build ios`
- **整合**: `flutter build ios-framework --output=./iOS/Frameworks`

## 🧪 测试策略
- **单元测试**：SwiftUI 部分使用 `XCTest`，Flutter 部分使用 `flutter test`。
- **UI 测试**：iOS 使用 `XCUITest`，Flutter 使用 `flutter driver`。
- **集成测试**：针对关键流程（如登录→首页）编写端到端测试。

## 📚 参考资料
- [SwiftUI 官方文档](https://developer.apple.com/documentation/swiftui)
- [Flutter 官方文档](https://flutter.dev/docs)
- [混合开发最佳实践](https://docs.flutter.dev/add-to-app)
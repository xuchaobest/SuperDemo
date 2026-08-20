//
//  TaskFlowVC.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - TaskFlowApp.swift
import SwiftUI
import UIKit
import SnapKit

/// 供 Objective-C 调用的容器控制器（使用组合模式封装 SwiftUI 视图）
@objc(TaskFlowVC)
class TaskFlowVC: UIViewController {

    private var hostingController: UIHostingController<ContentView>?
    private let viewModel: TaskViewModel

    /// 默认初始化方法（供 OC 调用）
    @objc init() {
        let viewModel = TaskViewModel(service: MockTaskService())
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUIView()
        // 加载数据
        Task { await viewModel.load() }
    }

    private func setupSwiftUIView() {
        let contentView = ContentView().environmentObject(viewModel)
        let hosting = UIHostingController(rootView: contentView)

        // 添加为子控制器
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.snp.makeConstraints { make in
            make.edges.equalToSuperview();
        }
//        NSLayoutConstraint.activate([
//            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
//            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
        hosting.didMove(toParent: self)
        self.hostingController = hosting as? UIHostingController<ContentView>
    }
}

/*
 TaskFlow
 ├── TaskFlowApp.swift               # 入口
 ├── Models
 │   └── TaskItem.swift              # 任务模型、分类、优先级
 ├── Services
 │   └── TaskService.swift           # 协议 + Mock 服务
 ├── ViewModels
 │   └── TaskViewModel.swift         # 主 ViewModel
 ├── Views
 │   ├── ContentView.swift           # 根 TabView
 │   ├── TaskListView.swift          # 任务列表
 │   ├── TaskRowView.swift           # 单行任务
 │   ├── TaskDetailView.swift        # 任务详情
 │   ├── TaskEditView.swift          # 新建/编辑表单
 │   └── StatisticsView.swift        # 统计页
 └── Components
     ├── Checkbox.swift              # 自定义复选框
     ├── PriorityBadge.swift         # 优先级标签
     └── EmptyStateView.swift        # 空状态视图
 */
/*
 
 技术点    案例中的体现
 @State    TaskEditView 中的 isSaving、showValidationError
 @Binding    TaskEditView(draft: $draft) 双向绑定草稿
 @StateObject    TaskFlowApp 中持有 TaskViewModel
 @EnvironmentObject    所有子视图共享 TaskViewModel
 @Environment    @Environment(\.dismiss)
 @AppStorage    外观设置
 @FocusState    表单焦点切换
 @Published + Combine    搜索防抖
 NavigationStack + navigationDestination    列表到详情
 sheet / confirmationDialog / alert    编辑、删除、错误提示
 searchable / refreshable    搜索与下拉刷新
 async/await + actor    模拟网络服务
 matchedGeometryEffect    统计页分段切换器
 隐式 + 显式动画    完成率动画、列表删除动画
 手势    DragGesture 左右滑动切换统计维度
 LazyVGrid    分类统计网格
 自定义组件    Checkbox、PriorityBadge、EmptyStateView
 */

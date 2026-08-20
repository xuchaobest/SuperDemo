//
//  ViewModels-TaskViewModel.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - ViewModels/TaskViewModel.swift

import SwiftUI
import Combine

// MARK: - 统计辅助类型

/// 分类统计
struct CategoryStat: Identifiable {
    var id: Category { category }
    let category: Category
    let count: Int
    let completedCount: Int

    var rate: Double {
        guard count > 0 else { return 0 }
        return Double(completedCount) / Double(count)
    }
}

/// 优先级统计
struct PriorityStat: Identifiable {
    var id: Priority { priority }
    let priority: Priority
    let count: Int
}

// MARK: - ViewModel

@MainActor
final class TaskViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    @Published var searchText = ""
    @Published private(set) var searchQuery = ""
    @Published var selectedFilter: Filter = .all
    @Published var sortOption: SortOption = .createdAt

    enum Filter: String, CaseIterable, Identifiable {
        case all = "全部"
        case active = "进行中"
        case completed = "已完成"
        var id: String { rawValue }
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case createdAt = "创建时间"
        case dueDate = "截止日期"
        case priority = "优先级"
        var id: String { rawValue }
    }

    private let service: any TaskServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: any TaskServiceProtocol) {
        self.service = service
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.searchQuery = newValue
            }
            .store(in: &cancellables)
    }

    var filteredTasks: [TaskItem] {
        var result = tasks

        // 1. 按完成状态筛选
        switch selectedFilter {
        case .all:
            break
        case .active:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        }

        // 2. 搜索过滤
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.details.localizedCaseInsensitiveContains(query)
            }
        }

        // 3. 排序
        switch sortOption {
        case .createdAt:
            result.sort { $0.createdAt > $1.createdAt }
        case .dueDate:
            result.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .priority:
            result.sort { $0.priority.rank > $1.priority.rank }
        }

        // ✅ 必须显式返回
        return result
    }

    var completionRate: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter(\.isCompleted).count) / Double(tasks.count)
    }

    var categoryStats: [CategoryStat] {
        Category.allCases.map { category in
            let categoryTasks = tasks.filter { $0.category == category }
            return CategoryStat(
                category: category,
                count: categoryTasks.count,
                completedCount: categoryTasks.filter(\.isCompleted).count
            )
        }
    }

    var priorityStats: [PriorityStat] {
        Priority.allCases.map { priority in
            PriorityStat(priority: priority, count: tasks.filter { $0.priority == priority }.count)
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            tasks = try await service.fetchTasks()
        } catch {
            errorMessage = "加载失败：\(error.localizedDescription)"
        }
    }

    func add(_ draft: TaskDraft) {
        let task = TaskItem(
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            details: draft.details,
            priority: draft.priority,
            category: draft.category,
            isCompleted: draft.isCompleted,
            dueDate: draft.dueDate
        )
        tasks.insert(task, at: 0)
        persist()
    }

    func update(_ id: UUID, with draft: TaskDraft) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        tasks[index].details = draft.details
        tasks[index].priority = draft.priority
        tasks[index].category = draft.category
        tasks[index].isCompleted = draft.isCompleted
        tasks[index].dueDate = draft.dueDate
        persist()
    }

    func toggle(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
        persist()
    }

    func delete(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        persist()
    }

    func delete(filteredAt offsets: IndexSet) {
        let ids = offsets.map { filteredTasks[$0].id }
        tasks.removeAll { ids.contains($0.id) }
        persist()
    }

    private func persist() {
        let snapshot = tasks
        let service = self.service
        // 使用 Task.detached 显式在后台执行保存（可选）
        Task.detached {
            try? await service.saveTasks(snapshot)
        }
    }
}

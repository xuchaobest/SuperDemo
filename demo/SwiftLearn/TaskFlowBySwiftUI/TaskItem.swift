//
//  Models:TaskItem.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - Models/TaskItem.swift

import SwiftUI

/// 任务优先级
enum Priority: String, CaseIterable, Codable, Hashable, Identifiable {
    case low = "低"
    case normal = "中"
    case high = "高"

    var id: String { rawValue }

    /// 用于排序
    var rank: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        }
    }

    var color: Color {
        switch self {
        case .low: return .blue
        case .normal: return .orange
        case .high: return .red
        }
    }

    var iconName: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .normal: return "equal.circle.fill"
        case .high: return "exclamationmark.circle.fill"
        }
    }
}

/// 任务分类
enum Category: String, CaseIterable, Codable, Hashable, Identifiable {
    case work = "工作"
    case personal = "个人"
    case study = "学习"
    case health = "健康"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .work: return .indigo
        case .personal: return .pink
        case .study: return .cyan
        case .health: return .green
        }
    }

    var iconName: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .study: return "book.fill"
        case .health: return "heart.fill"
        }
    }
}

/// 任务模型
struct TaskItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var details: String
    var priority: Priority
    var category: Category
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        priority: Priority = .normal,
        category: Category = .personal,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.priority = priority
        self.category = category
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.dueDate = dueDate
    }
}

/// 新建/编辑任务时的草稿，不需要 Identifiable
struct TaskDraft {
    var title: String = ""
    var details: String = ""
    var priority: Priority = .normal
    var category: Category = .personal
    var isCompleted: Bool = false
    var dueDate: Date? = nil

    init() {}

    init(task: TaskItem) {
        self.title = task.title
        self.details = task.details
        self.priority = task.priority
        self.category = task.category
        self.isCompleted = task.isCompleted
        self.dueDate = task.dueDate
    }
}

//
//  Services-TaskService.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - Services/TaskService.swift

import Foundation

protocol TaskServiceProtocol: Sendable {
    func fetchTasks() async throws -> [TaskItem]
    func saveTasks(_ tasks: [TaskItem]) async throws
}

actor MockTaskService: TaskServiceProtocol {
    private var storage: [TaskItem] = [
        TaskItem(
            title: "完成 SwiftUI 学习笔记",
            details: "整理状态管理、动画、布局等重要概念",
            priority: .high,
            category: .study,
            dueDate: .now.addingTimeInterval(86_400)
        ),
        TaskItem(
            title: "周五晨跑",
            details: "5 公里有氧训练",
            priority: .normal,
            category: .health,
            dueDate: .now.addingTimeInterval(172_800)
        ),
        TaskItem(
            title: "整理周报",
            details: "汇总本周工作进展与下周计划",
            priority: .normal,
            category: .work,
            dueDate: .now.addingTimeInterval(259_200)
        )
    ]

    func fetchTasks() async throws -> [TaskItem] {
        try await Task.sleep(nanoseconds: 600_000_000)
        return storage
    }

    func saveTasks(_ tasks: [TaskItem]) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        storage = tasks
    }
}

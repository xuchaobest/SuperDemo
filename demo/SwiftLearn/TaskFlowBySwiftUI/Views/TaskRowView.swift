//
//  Views-TaskRowView.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - Views/TaskRowView.swift

import SwiftUI

struct TaskRowView: View {
    @EnvironmentObject private var vm: TaskViewModel
    let task: TaskItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 自定义复选框
            Checkbox(isChecked: task.isCompleted) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    vm.toggle(task.id)
                }
            }

            // NavigationLink 负责跳转到详情
            if #available(iOS 16.0, *) {
                NavigationLink(value: task) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.headline)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)
                        if !task.details.isEmpty {
                            Text(task.details)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                // Fallback on earlier versions
            }  // 去掉 NavigationLink 默认蓝色

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                PriorityBadge(priority: task.priority)
                if let dueDate = task.dueDate {
                    Text(dueDate, format: .dateTime.month().day().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(task.isCompleted ? 0.55 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: task.isCompleted)
    }
}

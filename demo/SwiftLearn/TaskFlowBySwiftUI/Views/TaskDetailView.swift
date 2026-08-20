//
//  Views-TaskDetailView.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - Views/TaskDetailView.swift

import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject private var vm: TaskViewModel
    let task: TaskItem

    @State private var draft = TaskDraft()
    @State private var showingEditor = false
    @State private var showDeleteConfirm = false

    private var currentTask: TaskItem? {
        vm.tasks.first { $0.id == task.id }
    }

    var body: some View {
        Group {
            if let currentTask {
                detailContent(currentTask)
            } else {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView("任务不存在", systemImage: "questionmark.circle")
                } else {
                    // Fallback on earlier versions
                }
            }
        }
        .navigationTitle("任务详情")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        prepareEdit(currentTask)
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(currentTask == nil)
            }
        }
        .sheet(isPresented: $showingEditor) {
            TaskEditView(draft: $draft) { updated in
                if let currentTask {
                    vm.update(currentTask.id, with: updated)
                }
            }
        }
        .confirmationDialog(
            "确定删除这个任务吗？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let currentTask {
                    vm.delete(currentTask.id)
                }
            }
            Button("取消", role: .cancel) {}
        }
    }

    private func detailContent(_ currentTask: TaskItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 12) {
                    Checkbox(isChecked: currentTask.isCompleted) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            vm.toggle(currentTask.id)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentTask.title)
                            .font(.largeTitle.bold())
                            .strikethrough(currentTask.isCompleted)
                        Text("创建于 \(currentTask.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !currentTask.details.isEmpty {
                    Text(currentTask.details)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                }

                HStack(spacing: 12) {
                    PriorityBadge(priority: currentTask.priority)
                    Label(currentTask.category.rawValue, systemImage: currentTask.category.iconName)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(currentTask.category.color.opacity(0.18), in: Capsule())
                        .foregroundStyle(currentTask.category.color)
                }

                if let dueDate = currentTask.dueDate {
                    Label(dueDate.formatted(date: .long, time: .shortened), systemImage: "calendar")
                        .font(.subheadline)
                }
            }
            .padding()
        }
    }

    private func prepareEdit(_ task: TaskItem?) {
        guard let task else { return }
        draft = TaskDraft(task: task)
        showingEditor = true
    }
}

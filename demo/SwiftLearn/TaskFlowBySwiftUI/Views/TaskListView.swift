//
//  Views-TaskListView.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - Views/TaskListView.swift

import SwiftUI
import MJRefresh

struct TaskListView: View {
    @EnvironmentObject private var vm: TaskViewModel
    @AppStorage("appearance") private var appearance = "system"

    @State private var draft = TaskDraft()
    @State private var editingID: UUID?
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("任务清单")
                .searchable(text: $vm.searchText, prompt: "搜索任务")
                .toolbar { toolbarContent }
                .navigationDestination(for: TaskItem.self) { task in
                    TaskDetailView(task: task)
                }
                .sheet(isPresented: $showingEditor) {
                    TaskEditView(draft: $draft) { updated in
                        if let editingID {
                            vm.update(editingID, with: updated)
                        } else {
                            vm.add(updated)
                        }
                    }
                }
                .alert(
                    "出错了",
                    isPresented: Binding(
                        get: { vm.errorMessage != nil },
                        set: { if !$0 { vm.errorMessage = nil } }
                    )
                ) {
                    Button("好", role: .cancel) { vm.errorMessage = nil }
                } message: {
                    Text(vm.errorMessage ?? "未知错误")
                }
        }
    }

    // MARK: - 内容区
    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            ProgressView("正在加载任务…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.filteredTasks.isEmpty {
            EmptyStateView(
                symbol: vm.tasks.isEmpty ? "tray" : "magnifyingglass",
                title: vm.tasks.isEmpty ? "还没有任务" : "没有匹配结果",
                message: vm.tasks.isEmpty ? "点击右上角 + 创建一个新任务" : "试试调整搜索词或筛选条件",
                actionTitle: vm.tasks.isEmpty ? "创建任务" : nil,
                action: vm.tasks.isEmpty ? { presentNew() } : nil
            )
        } else {
            taskList
        }
    }

    private var taskList: some View {
        List {
            Section {
                ForEach(vm.filteredTasks) { task in
                    TaskRowView(task: task)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    vm.delete(task.id)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }

                            Button {
                                editingID = task.id
                                draft = TaskDraft(task: task)
                                showingEditor = true
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    vm.toggle(task.id)
                                }
                            } label: {
                                Label(
                                    task.isCompleted ? "标记未完成" : "标记完成",
                                    systemImage: task.isCompleted ? "circle" : "checkmark.circle"
                                )
                            }
                            Button(role: .destructive) {
                                vm.delete(task.id)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            } header: {
                listHeader
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await vm.load() }  // 下拉刷新
    }

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("共 \(vm.filteredTasks.count) 项")
                Spacer()
                Text("完成率\(Int(vm.completionRate * 100))%")
                    .contentTransition(.numericText())  // 数字变化动画
            }
            .font(.caption)
            ProgressView(value: vm.completionRate)
                .tint(.green)
        }
        .padding(.vertical, 4)
    }

    // MARK: - 工具栏
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("筛选", selection: $vm.selectedFilter) {
                    ForEach(TaskViewModel.Filter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                Divider()
                Picker("排序", selection: $vm.sortOption) {
                    ForEach(TaskViewModel.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                Divider()
                Picker("外观", selection: $appearance) {
                    Text("系统").tag("system")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(action: presentNew) {
                Image(systemName: "plus.circle.fill")
            }
            .accessibilityLabel("新建任务")
        }
    }

    // MARK: - 方法
    private func presentNew() {
        editingID = nil
        draft = TaskDraft()
        showingEditor = true
    }
}

//
//  Views-askEditView.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - Views/TaskEditView.swift

import SwiftUI

struct TaskEditView: View {
    @Binding var draft: TaskDraft
    let onSave: (TaskDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var showValidationError = false
    @State private var isSaving = false

    enum Field: Hashable {
        case title
        case details
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $draft.title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .details }
                    TextField("备注", text: $draft.details, axis: .vertical)
                        .focused($focusedField, equals: .details)
                        .lineLimit(3...6)
                    Toggle("已完成", isOn: $draft.isCompleted)
                }

                Section("分类与优先级") {
                    Picker("分类", selection: $draft.category) {
                        ForEach(Category.allCases) { category in
                            Label(category.rawValue, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                    Picker("优先级", selection: $draft.priority) {
                        ForEach(Priority.allCases) { priority in
                            Label(priority.rawValue, systemImage: priority.iconName)
                                .tag(priority)
                        }
                    }
                }

                Section("截止日期") {
                    Toggle("设置截止日期", isOn: Binding(
                        get: { draft.dueDate != nil },
                        set: { draft.dueDate = $0 ? Date().addingTimeInterval(3600) : nil }
                    ))
                    if draft.dueDate != nil {
                        DatePicker(
                            "截止时间",
                            selection: Binding(
                                get: { draft.dueDate ?? Date() },
                                set: { draft.dueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section {
                    Button(action: save) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(isSaving ? "保存中…" : "保存")
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle(draft.title.isEmpty ? "新建任务" : "编辑任务")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                focusedField = .title
            }
            .interactiveDismissDisabled(isSaving)  // 保存时禁止下滑关闭
            .alert("标题不能为空", isPresented: $showValidationError) {
                Button("好", role: .cancel) {}
            } message: {
                Text("请输入任务标题")
            }
        }
    }

    private func save() {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            showValidationError = true
            return
        }
        draft.title = trimmedTitle
        isSaving = true

        // 模拟保存延迟，展示异步处理
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            isSaving = false
            onSave(draft)
            dismiss()
        }
    }
}

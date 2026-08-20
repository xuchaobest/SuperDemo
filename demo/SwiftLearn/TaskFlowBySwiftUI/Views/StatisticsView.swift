//
//  Views-StatisticsView.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - Views/StatisticsView.swift

import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var vm: TaskViewModel
    @Namespace private var segmentNamespace
    @State private var selectedScope: StatisticsScope = .category

    enum StatisticsScope: String, CaseIterable, Identifiable {
        case category = "分类统计"
        case priority = "优先级分布"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    completionCard
                    scopePicker

                    if selectedScope == .category {
                        categoryStatsGrid
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        priorityStatsList
                            .transition(.opacity)
                    }
                }
                .padding()
            }
            .navigationTitle("统计")
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedScope)
        }
    }

    // MARK: - 完成率卡片
    private var completionCard: some View {
        VStack(spacing: 16) {
            Text("完成率")
                .font(.headline)
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: CGFloat(vm.completionRate))
                    .stroke(
                        AngularGradient(colors: [.blue, .purple, .pink], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: vm.completionRate)
                VStack(spacing: 4) {
                    Text("\(Int(vm.completionRate * 100))%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("\(vm.tasks.filter(\.isCompleted).count) / \(vm.tasks.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 170, height: 170)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 分段切换器
    private var scopePicker: some View {
        HStack(spacing: 0) {
            ForEach(StatisticsScope.allCases) { scope in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedScope = scope
                    }
                } label: {
                    ZStack {
                        if selectedScope == scope {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor.opacity(0.15))
                                .matchedGeometryEffect(id: "scope_background", in: segmentNamespace)
                        }
                        Text(scope.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedScope == scope ? Color.accentColor : Color.secondary)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(4)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width > 80 {
                        withAnimation { selectedScope = .category }
                    } else if value.translation.width < -80 {
                        withAnimation { selectedScope = .priority }
                    }
                }
        )
    }

    // MARK: - 分类统计网格
    private var categoryStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            ForEach(vm.categoryStats) { stat in
                VStack(alignment: .leading, spacing: 8) {
                    Label(stat.category.rawValue, systemImage: stat.category.iconName)
                        .font(.headline)
                        .foregroundStyle(stat.category.color)
                    Text("\(stat.count) 项")
                        .font(.title3.weight(.bold))
                    ProgressView(value: stat.rate)
                        .tint(stat.category.color)
                    Text("完成 \(stat.completedCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - 优先级分布列表
    private var priorityStatsList: some View {
        VStack(spacing: 12) {
            ForEach(vm.priorityStats) { stat in
                HStack {
                    PriorityBadge(priority: stat.priority)
                    Spacer()
                    Text("\(stat.count) 项")
                        .font(.headline)
                }
                .padding()
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

//
//  Views-ContentView.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - Views/ContentView.swift

import SwiftUI

enum AppTab: Hashable {
    case list
    case stats
}

struct ContentView: View {
    @EnvironmentObject private var vm: TaskViewModel
    @AppStorage("appearance") private var appearance = "system"
    @State private var selectedTab: AppTab = .list

    var body: some View {
        TabView(selection: $selectedTab) {
            TaskListView()
                .tabItem { Label("任务", systemImage: "checklist") }
                .tag(AppTab.list)

            StatisticsView()
                .tabItem { Label("统计", systemImage: "chart.bar.xaxis") }
                .tag(AppTab.stats)
        }
        .preferredColorScheme(
            appearance == "dark" ? .dark : (appearance == "light" ? .light : nil)
        )
    }
}

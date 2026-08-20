//
//  Components-Checkbox.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - Components/Checkbox.swift

import SwiftUI

struct Checkbox: View {
    let isChecked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            if #available(iOS 17.0, *) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isChecked ? Color.green : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
            } else {
                // Fallback on earlier versions
            }  // SF Symbol 切换动画
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isChecked ? "标记未完成" : "标记完成")
    }
}

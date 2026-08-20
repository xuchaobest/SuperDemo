//
//  Components-PriorityBadge.swift
//  demo
//
//  Created by RichardX on 2026/8/18.
//

// MARK: - Components/PriorityBadge.swift

import SwiftUI

struct PriorityBadge: View {
    let priority: Priority

    var body: some View {
        Label(priority.rawValue, systemImage: priority.iconName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color.opacity(0.18), in: Capsule())
            .foregroundStyle(priority.color)
    }
}

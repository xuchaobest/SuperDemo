//
//  Message.swift
//  demo
//
//  Created by RichardX on 2026/8/12.
//
import Foundation
@preconcurrency import WCDBSwift

struct Message: TableCodable, Identifiable {
    var id: String = UUID().uuidString   // 客户端生成唯一 ID
    var role: String
    var content: String
    var timestamp: Date = Date()
    var isCompleted: Bool = true

    enum CodingKeys: String, CodingTableKey {
        typealias Root = Message
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true, isNotNull: true)     // 主键，非空，无自增
            BindColumnConstraint(role, isNotNull: true)
            BindColumnConstraint(content, isNotNull: true, defaultTo: "")
            BindColumnConstraint(timestamp, isNotNull: true)
            BindColumnConstraint(isCompleted, isNotNull: true, defaultTo: true)
        }

        case id
        case role
        case content
        case timestamp
        case isCompleted
    }
}

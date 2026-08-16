//
//  DatabaseManager.swift
//  demo
//
//  Created by RichardX on 2026/8/12.
//

import Foundation
import WCDBSwift

final class DatabaseManager: @unchecked Sendable {
    static let shared = DatabaseManager()
    private let database: Database
    private let queue = DispatchQueue(label: "com.deepseek.db", qos: .utility)

    private init() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/deepseek_chat.db"
        database = Database(at: path)
        queue.sync {
            do {
                try database.create(table: "message", of: Message.self)
            } catch {
                print("DB create error: \(error)")
            }
        }
    }

    // completion 加上 @Sendable
    func fetchMessages(completion: @escaping @Sendable ([Message]) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                let messages: [Message] = try self.database.getObjects(
                    fromTable: "message",
                    orderBy: [Message.Properties.timestamp.asOrder()]
                )
                DispatchQueue.main.async {
                    completion(messages)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }

    func insert(message: Message, completion: @escaping @Sendable (Message) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.database.insert(message, intoTable: "message")
                // 插入成功，直接返回原对象（id 已包含）
                DispatchQueue.main.async {
                    completion(message)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(message) // 失败也返回原对象，调用方可判断 id 是否为空？
                }
            }
        }
    }

    func updateContent(_ content: String, forMessageId id: String, isCompleted: Bool = false) {
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.database.update(
                    table: "message",
                    on: [Message.Properties.content, Message.Properties.isCompleted],
                    with: [content, isCompleted],
                    where: Message.Properties.id == id
                )
            } catch {
                print("Update error: \(error)")
            }
        }
    }
}

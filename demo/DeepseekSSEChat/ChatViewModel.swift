//
//  ChatViewModel.swift
//  demo
//
//  Created by RichardX on 2026/8/12.
//

import SwiftUI
import Combine

enum APIKeyStatus {
    case notStored
    case stored
}

enum ConnectionState {
    case idle
    case checking
    case connected
    case error(String)
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var apiKeyStatus: APIKeyStatus = .notStored
    @Published var connectionState: ConnectionState = .idle
    @Published var inputText: String = ""
    @Published var autoScroll: Bool = true
    @Published var showAPIKeyCard: Bool = false
    @Published private(set) var currentStreamTask: Task<Void, Never>? // 允许视图读取

    private var streamManager: DeepSeekStreamManager?
    private var streamingMessageId: String?  // UUID 字符串

    init() {
        checkAPIKey()
    }

    func checkAPIKey() {
        if let key = SecureStorage.getAPIKey(), !key.isEmpty {
            apiKeyStatus = .stored
            streamManager = DeepSeekStreamManager(apiKey: key)
            connectionState = .idle
            loadMessages()
            checkConnectivity()
        } else {
            apiKeyStatus = .notStored
            showAPIKeyCard = true
            connectionState = .idle
        }
    }

    func saveAPIKey(_ key: String) {
        guard !key.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try SecureStorage.saveAPIKey(key)
            apiKeyStatus = .stored
            showAPIKeyCard = false
            streamManager = DeepSeekStreamManager(apiKey: key)
            loadMessages()
            checkConnectivity()
        } catch {
            connectionState = .error("Keychain 存储失败")
        }
    }

    func checkConnectivity() {
        guard let key = SecureStorage.getAPIKey() else { return }
        connectionState = .checking

        Task {
            guard let url = URL(string: "https://api.deepseek.com/v1/models") else {
                self.connectionState = .error("无效的 URL")
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.connectionState = .connected
                } else {
                    self.connectionState = .error("服务器响应异常")
                }
            } catch {
                self.connectionState = .error(error.localizedDescription)
            }
        }
    }

    func loadMessages() {
        DatabaseManager.shared.fetchMessages { [weak self] msgs in
            Task { @MainActor [weak self] in
                self?.messages = msgs
            }
        }
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard let streamManager = streamManager else {
            connectionState = .error("API Key 未配置")
            return
        }

        currentStreamTask?.cancel()
        streamingMessageId = nil

        inputText = ""
        autoScroll = true

        let userMessage = Message(role: "user", content: text, timestamp: Date(), isCompleted: true)

        DatabaseManager.shared.insert(message: userMessage) { [weak self] insertedMsg in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.messages.append(insertedMsg)

                let assistantMsg = Message(role: "assistant", content: "", timestamp: Date(), isCompleted: false)
                self.streamingMessageId = assistantMsg.id

                DatabaseManager.shared.insert(message: assistantMsg) { [weak self] aiMsg in
                    guard let self else { return }
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.messages.append(aiMsg)

                        let apiMessages = self.buildAPIMessages()

                        self.currentStreamTask = Task { [weak self] in
                            guard let self else { return }
                            do {
                                let stream = await streamManager.stream(messages: apiMessages)
                                for try await event in stream {
                                    if Task.isCancelled { break }
                                    switch event {
                                    case .content(let delta):
                                        self.handleDelta(delta)
                                    case .thinking(let reasoning):
                                        print("Thinking: \(reasoning)")
                                    case .done:
                                        self.handleStreamCompletion()
                                    }
                                }
                            } catch {
                                if !Task.isCancelled {
                                    // 直接在主 actor 上下文中处理错误
                                    self.handleStreamError(error)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func stopStream() {
        currentStreamTask?.cancel()
        currentStreamTask = nil
        if let id = streamingMessageId {
            if let index = messages.firstIndex(where: { $0.id == id }) {
                var msg = messages[index]
                msg.isCompleted = true
                messages[index] = msg
                DatabaseManager.shared.updateContent(msg.content, forMessageId: id, isCompleted: true)
            }
            streamingMessageId = nil
        }
    }

    private func buildAPIMessages() -> [[String: String]] {
        var apiMsgs: [[String: String]] = []
        for msg in messages {
            if msg.isCompleted {
                apiMsgs.append(["role": msg.role, "content": msg.content])
            }
        }
        return apiMsgs
    }

    private func handleDelta(_ text: String) {
        guard let id = streamingMessageId,
              let index = messages.firstIndex(where: { $0.id == id }) else { return }

        var msg = messages[index]
        msg.content += text
        messages[index] = msg

        DatabaseManager.shared.updateContent(msg.content, forMessageId: id, isCompleted: false)

        if autoScroll {
            // 自动滚动由视图层监听 messages 变化触发
        }
    }

    private func handleStreamCompletion() {
        guard let id = streamingMessageId else { return }
        if let index = messages.firstIndex(where: { $0.id == id }) {
            var msg = messages[index]
            msg.isCompleted = true
            messages[index] = msg
            DatabaseManager.shared.updateContent(msg.content, forMessageId: id, isCompleted: true)
        }
        streamingMessageId = nil
        currentStreamTask = nil   // 隐藏停止按钮
    }

    private func handleStreamError(_ error: Error) {
        connectionState = .error(error.localizedDescription)

        if let id = streamingMessageId {
            if let index = messages.firstIndex(where: { $0.id == id }) {
                var msg = messages[index]
                if !msg.content.isEmpty {
                    msg.content += "\n"
                }
                msg.content += "[错误] \(error.localizedDescription)"
                msg.isCompleted = true
                messages[index] = msg
                DatabaseManager.shared.updateContent(msg.content, forMessageId: id, isCompleted: true)
            }
            streamingMessageId = nil
        }
        currentStreamTask = nil
    }
}

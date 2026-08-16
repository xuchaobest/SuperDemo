//
//  ChatView.swift
//  demo
//
//  Created by RichardX on 2026/8/12.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var keyboardHeight: CGFloat = 0
    @State private var apiKeyInput: String = ""

    var body: some View {
        ZStack {
            // 背景
            Color(.systemGray6)
                .ignoresSafeArea()

            // 主内容
            VStack(spacing: 0) {
                connectionStatusBar
                messageList
                inputBar
            }

            // API Key 卡片
            if viewModel.showAPIKeyCard {
                apiKeyCard
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("DeepSeek")
                    .fontWeight(.semibold)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notif in
            if let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = frame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    // MARK: - 连接状态栏
    private var connectionStatusBar: some View {
        Group {
            if case .checking = viewModel.connectionState {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("验证 API Key...")
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
            } else if case .error(let msg) = viewModel.connectionState {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("连接失败: \(msg)")
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Button("重试") {
                        viewModel.checkConnectivity()
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
            }
        }
    }

    // MARK: - 消息列表
    private var messageList: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .coordinateSpace(name: "scroll")
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if value.translation.height < -10 {
                            viewModel.autoScroll = false
                        }
                    }
            )
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(proxy: scrollProxy)
            }
            .onChange(of: viewModel.messages.last?.content) { _ in
                scrollToBottom(proxy: scrollProxy)
            }
            .onChange(of: viewModel.autoScroll) { newValue in
                if newValue {
                    scrollToBottom(proxy: scrollProxy)
                }
            }
        }
    }

    // MARK: - 输入栏
    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("输入消息...", text: $viewModel.inputText)
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(20)
                .submitLabel(.send)
                .onSubmit {
                    viewModel.sendMessage()
                }

            if viewModel.currentStreamTask != nil {
                Button(action: viewModel.stopStream) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                }
            }

            Button(action: viewModel.sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .padding(.bottom, keyboardHeight)
    }

    // MARK: - API Key 卡片
    private var apiKeyCard: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // 阻止点击穿透
                }

            VStack(spacing: 20) {
                Text("设置 API Key")
                    .font(.headline)

                SecureField("输入 DeepSeek API Key", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Button {
                    viewModel.saveAPIKey(apiKeyInput)
                    apiKeyInput = ""
                } label: {
                    Text("存储 API Key")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(25)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - 滚动到底部
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard viewModel.autoScroll, let lastId = viewModel.messages.last?.id else { return }
        withAnimation {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }
}

// MARK: - 聊天气泡（保持不变）
struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer(minLength: 60)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(18, corners: [.topLeft, .topRight, .bottomLeft])
                    if message.isCompleted {
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else {
                        HStack(spacing: 4) {
                            ProgressView().scaleEffect(0.6)
                            Text("生成中...")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.content)
                        .padding(12)
                        .background(Color(.systemGray5))
                        .cornerRadius(18, corners: [.topLeft, .topRight, .bottomRight])
                        .foregroundColor(.primary)
                    if message.isCompleted {
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else {
                        HStack(spacing: 4) {
                            ProgressView().scaleEffect(0.6)
                            Text("生成中...")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

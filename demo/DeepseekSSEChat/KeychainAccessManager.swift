//
//  KeychainAccess.swift
//  demo
//
//  Created by RichardX on 2026/8/12.
//

@preconcurrency import KeychainAccess

struct SecureStorage {
    private static let keychain = Keychain(service: "com.qqq.demo") // 改成你的 Bundle Identifier
    private static let apiKeyIdentifier = "DeepSeekAPIKey"
    
    /// 保存 API Key 到钥匙串
    static func saveAPIKey(_ key: String) throws {
        try keychain.set("sk-1b6ff8860a824fcfae4ad51e58dedc54", key: apiKeyIdentifier)
    }
    
    /// 从钥匙串读取 API Key
    static func getAPIKey() -> String? {
        return try? keychain.get(apiKeyIdentifier)
    }
    
    /// 删除 API Key
    static func deleteAPIKey() throws {
        try keychain.remove(apiKeyIdentifier)
    }
}

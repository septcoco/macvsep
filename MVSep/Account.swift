import Foundation
import Observation
import Security

/// The user's API key (kept in the Keychain) and what MVSep says about their account.
@MainActor @Observable
final class Account {
    static let shared = Account()

    var apiKey: String {
        didSet {
            guard apiKey != oldValue else { return }
            Keychain.save(apiKey, for: Self.keychainAccount)
            user = nil
        }
    }
    private(set) var user: UserInfo?
    private(set) var errorMessage: String?
    private(set) var isUpdatingPremium = false

    /// Premium perks (premium formats and models, parallel jobs) only apply while credits can be spent.
    var isPremiumActive: Bool { (user?.credits ?? 0) > 0 && (user?.premiumEnabled ?? false) }

    private static let keychainAccount = "apiKey"

    private init() {
        // Earlier versions kept the key in UserDefaults; move it over once.
        if let legacyKey = UserDefaults.standard.string(forKey: "apiKey"), !legacyKey.isEmpty {
            Keychain.save(legacyKey, for: Self.keychainAccount)
            UserDefaults.standard.removeObject(forKey: "apiKey")
        }
        apiKey = Keychain.load(Self.keychainAccount) ?? ""
    }

    func refresh() async {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { user = nil; errorMessage = nil; return }
        do {
            let user = try await APIService.shared.fetchUser(apiKey: key)
            guard key == apiKey.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            self.user = user; errorMessage = nil
        } catch {
            user = nil; errorMessage = error.localizedDescription
        }
    }

    func setPremiumEnabled(_ enabled: Bool) async {
        isUpdatingPremium = true
        defer { isUpdatingPremium = false }
        do {
            try await APIService.shared.setPremiumEnabled(enabled, apiKey: apiKey)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        await refresh()
    }
}

enum Keychain {
    private static let service = Bundle.main.bundleIdentifier ?? "com.septcoco.MacVSep"

    static func save(_ value: String, for account: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty else { return }
        var item = query
        item[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(item as CFDictionary, nil)
    }

    static func load(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account,
            kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

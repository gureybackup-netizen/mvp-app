import Foundation
import MatrixRustSDK

class SessionManager {
    static let shared = SessionManager()
    var currentClient: MatrixClient?
    
    private let serviceName = "com.vardchat.app.auth"
    
    private init() {}
    
    func save(token: String, userId: String) {
        let credentials = ["token": token, "userId": userId]
        if let data = try? JSONEncoder().encode(credentials) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecValueData as String: data
            ]
            SecItemDelete(query as CFDictionary)
            SecItemAdd(query as CFDictionary, nil)
        }
    }
    
    func load() -> (token: String, userId: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data,
              let creds = try? JSONDecoder().decode([String: String].self, from: data),
              let token = creds["token"], let userId = creds["userId"] else {
            return nil
        }
        
        return (token, userId)
    }
    
    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        SecItemDelete(query as CFDictionary)
        currentClient = nil
    }
}

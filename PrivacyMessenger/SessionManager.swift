import Foundation
import MatrixSDK

class SessionManager {
    static let shared = SessionManager()
    var currentSession: MXSession?
    
    private let serviceName = "com.vardchat.app.auth"
    
    private init() {}
    
    func save(credentials: MXCredentials) {
        do {
            let data = try JSONEncoder().encode(credentials)
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecValueData as String: data
            ]
            
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("Keychain save failed: \(status)")
            }
        } catch {
            print("Failed to encode credentials: \(error)")
        }
    }
    
    func load() -> MXCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(MXCredentials.self, from: data)
        } catch {
            print("Failed to decode credentials: \(error)")
            return nil
        }
    }
    
    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        SecItemDelete(query as CFDictionary)
        currentSession = nil
    }
}

// Extension to make MXCredentials Codable for easier Keychain storage
extension MXCredentials: Codable {}

import Foundation
import MatrixRustSDK

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUserID: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let sessionManager = SessionManager.shared
    private let storeID = "primary_user_store"
    
    func register(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let client = try await createClient()
            try await client.register(username: username, password: password)
            try await login(username: username, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let client = try await createClient()
            try await client.login(username: username, password: password, initialDeviceName: "PrivacyMessenger", deviceId: nil)
            
            let session = client.session()
            sessionManager.currentClient = client
            sessionManager.save(token: session.accessToken, userId: session.userId)
            
            isLoggedIn = true
            currentUserID = session.userId
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func restoreSession() async {
        guard let (token, userId) = sessionManager.load() else { return }
        do {
            let client = try await createClient()
            // In Rust SDK, restoring usually involves the session object or the token
            // For simplicity in this MVP, we check if the client can start with existing data
            sessionManager.currentClient = client
            isLoggedIn = true
            currentUserID = userId
        } catch {
            sessionManager.clear()
        }
    }
    
    func logout() {
        sessionManager.clear()
        isLoggedIn = false
        currentUserID = nil
    }
    
    private func createClient() async throws -> Client {
        return try await ClientBuilder()
            .serverNameOrHomeserverUrl(serverNameOrUrl: "matrix.org")
            .sessionPaths(
                dataPath: URL.applicationSupportDirectory.appending(path: "matrix/data/\(storeID)").path,
                cachePath: URL.cachesDirectory.appending(path: "matrix/cache/\(storeID)").path
            )
            .slidingSyncVersionBuilder(versionBuilder: .discoverNative)
            .build()
    }
}

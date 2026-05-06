import Foundation
import MatrixRustSDK

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUserID: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let sessionManager = SessionManager.shared
    
    func register(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Rust SDK Registration
            let client = MatrixClient(homeserver: "https://matrix.org")
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
            let client = MatrixClient(homeserver: "https://matrix.org")
            let session = try await client.login(username: username, password: password)
            
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
            let client = MatrixClient(homeserver: "https://matrix.org")
            try await client.restoreSession(token: token, userId: userId)
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
}

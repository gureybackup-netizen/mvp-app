import Foundation
import MatrixSDK

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
            try await performRegistration(username: username, password: password)
            try await login(username: username, password: password)
        } catch {
            errorMessage = mapMatrixError(error)
        }
        isLoading = false
    }
    
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let credentials = try await performLogin(username: username, password: password)
            try await startSession(credentials: credentials)
            isLoggedIn = true
            currentUserID = sessionManager.currentSession?.userId
        } catch {
            errorMessage = mapMatrixError(error)
        }
        isLoading = false
    }
    
    func restoreSession() async {
        guard let credentials = sessionManager.load() else { return }
        do {
            try await startSession(credentials: credentials)
            isLoggedIn = true
            currentUserID = sessionManager.currentSession?.userId
        } catch {
            sessionManager.clear()
        }
    }
    
    func logout() {
        sessionManager.clear()
        isLoggedIn = false
        currentUserID = nil
    }
    
    private func performRegistration(username: String, password: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let client = MXRestClient(url: URL(string: "https://matrix.org")!)
            client.register(username: username, password: password) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "Auth", code: 0))
                }
            }
        }
    }
    
    private func performLogin(username: String, password: String) async throws -> MXCredentials {
        return try await withCheckedThrowingContinuation { continuation in
            let client = MXRestClient(url: URL(string: "https://matrix.org")!)
            client.login(username: username, password: password) { credentials, error in
                if let credentials = credentials {
                    continuation.resume(returning: credentials)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "Auth", code: 0))
                }
            }
        }
    }
    
    private func startSession(credentials: MXCredentials) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let session = MXSession(credentials: credentials)
            
            // K7: Enable crypto before starting
            session.enableCrypto()
            
            // K9: Pass MXFileStore to start
            session.start(with: MXFileStore()) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    sessionManager.currentSession = session
                    sessionManager.save(credentials: credentials)
                    continuation.resume()
                }
            }
        }
    }
    
    private func mapMatrixError(_ error: Error) -> String {
        let nsError = error as NSError
        let code = nsError.domain == "MXErrorDomain" ? nsError.localizedDescription : ""
        
        if code.contains("M_USER_IN_USE") { return "Username is already taken." }
        if code.contains("M_FORBIDDEN") { return "Access forbidden." }
        if code.contains("M_LIMIT_EXCEEDED") { return "Too many requests. Please try again later." }
        if code.contains("M_NOT_FOUND") { return "User not found." }
        
        return nsError.localizedDescription
    }
}

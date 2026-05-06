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
    private let homeserverUrl = "https://matrix.org"
    
    func register(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Registration must be done via REST API as the Rust Client requires an existing session
            try await performRestRegistration(username: username, password: password)
            await login(username: username, password: password)
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
            // Fixed: deviceId must be a String, not nil
            try await client.login(username: username, password: password, initialDeviceName: "PrivacyMessenger", deviceId: "")
            
            let session = try client.session()
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
            
            // Fixed: deviceId and refreshToken must be Strings, not nil
            let session = Session(
                accessToken: token,
                refreshToken: "",
                userId: userId,
                deviceId: "",
                homeserverUrl: homeserverUrl,
                oidcData: nil,
                slidingSyncVersion: .native
            )
            try await client.restoreSession(session: session)
            
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
            .serverNameOrHomeserverUrl(serverNameOrUrl: homeserverUrl)
            .sessionPaths(
                dataPath: URL.applicationSupportDirectory.appending(path: "matrix/data/\(storeID)").path,
                cachePath: URL.cachesDirectory.appending(path: "matrix/cache/\(storeID)").path
            )
            .slidingSyncVersionBuilder(versionBuilder: .discoverNative)
            .build()
    }
    
    private func performRestRegistration(username: String, password: String) async throws {
        guard let url = URL(string: "\(homeserverUrl)/_matrix/client/r0/register") else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid registration URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Registration failed. Username might be taken."])
        }
    }
}

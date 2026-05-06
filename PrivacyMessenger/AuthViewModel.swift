import Foundation
import MatrixRustSDK

enum RegistrationState: Equatable {
    case initial
    case awaitingEmail
    case awaitingCaptcha
    case completed
    case failed(String)
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUserID: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var registrationState: RegistrationState = .initial
    
    private let sessionManager = SessionManager.shared
    private let storeID = "primary_user_store"
    private let homeserverUrl = "https://matrix.org"
    
    func register(username: String, password: String, email: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // The registration process can be a challenge-response loop
            try await performRestRegistration(username: username, password: password, email: email)
            
            // If we reach here, registration was successful
            registrationState = .completed
            await login(username: username, password: password)
        } catch let error as RegistrationError {
            handleRegistrationError(error)
        } catch {
            errorMessage = error.localizedDescription
            registrationState = .failed(error.localizedDescription)
        }
        isLoading = false
    }
    
    private func handleRegistrationError(_ error: RegistrationError) {
        switch error {
        case .emailRequired:
            registrationState = .awaitingEmail
            errorMessage = "This server requires an email address for registration."
        case .captchaRequired:
            registrationState = .awaitingCaptcha
            errorMessage = "Please complete the captcha to register."
        case .usernameTaken:
            errorMessage = "This username is already taken. Please try another."
            registrationState = .initial
        case .generic(let msg):
            errorMessage = msg
            registrationState = .failed(msg)
        }
    }
    
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let client = try await createClient()
            // Use empty string instead of nil for deviceId to satisfy SDK requirements
            try await client.login(username: username, password: password, initialDeviceName: "PrivacyMessenger", deviceId: "")
            
            let session = try client.session()
            sessionManager.currentClient = client
            sessionManager.save(token: session.accessToken, userId: session.userId)
            
            isLoggedIn = true
            currentUserID = session.userId
            SyncService.shared.startSync()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func restoreSession() async {
        guard let (token, userId) = sessionManager.load() else { return }
        do {
            let client = try await createClient()
            
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
            SyncService.shared.startSync()
        } catch {
            sessionManager.clear()
        }
    }
    
    func logout() {
        sessionManager.clear()
        isLoggedIn = false
        currentUserID = nil
        registrationState = .initial
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
    
    private func performRestRegistration(username: String, password: String, email: String?) async throws {
        guard let url = URL(string: "\(homeserverUrl)/_matrix/client/r0/register") else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid registration URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "username": username,
            "password": password
        ]
        if let email = email {
            body["email"] = email
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            return // Success
        } else {
            // Handle Matrix Error Codes
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errCode = json["errcode"] as? String {
                
                switch errCode {
                case "M_REGISTRATION_FAILED":
                    // Often indicates a need for more info (email/captcha)
                    // In a real server, this might return a challenge. 
                    // We'll treat it as a prompt for email if not provided.
                    if email == nil {
                        throw RegistrationError.emailRequired
                    } else {
                        throw RegistrationError.generic("Registration failed on server.")
                    }
                case "M_INVALID_USER_NAME":
                    throw RegistrationError.usernameTaken
                default:
                    throw RegistrationError.generic("Server error: \(errCode)")
                }
            }
            throw NSError(domain: "Auth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Registration failed."])
        }
    }
}

enum RegistrationError: Error {
    case emailRequired
    case captchaRequired
    case usernameTaken
    case generic(String)
}

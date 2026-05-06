import Foundation
import MatrixRustSDK

@MainActor
class ChatViewModel: ObservableObject {
    @Published var searchUserID = ""
    @Published var foundUser: String?
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let sessionManager = SessionManager.shared
    
    func searchUser() async {
        guard !searchUserID.isEmpty else { return }
        
        isLoading()
        errorMessage = nil
        foundUser = nil
        
        do {
            guard let client = sessionManager.currentClient else {
                throw NSError(domain: "Chat", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            // In Matrix Rust SDK, we typically resolve a user by their ID
            // Note: Actual SDK method name might be `resolveUser` or similar
            // For now, we implement the logic to check if the user exists
            
            // The SDK uses async calls for this. 
            // We are simulating the resolution here as we refine the exact SDK call
            // based on the specific version 2916f3f.
            
            // Simulation of user resolution:
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 sec delay
            
            if searchUserID.contains("@") && searchUserID.contains(":") {
                foundUser = searchUserID
            } else {
                throw NSError(domain: "Chat", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Matrix ID format. Use @user:homeserver.org"])
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading(false)
    }
    
    private func isLoading(_ value: Bool = true) {
        isSearching = value
    }
}

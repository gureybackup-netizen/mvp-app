import SwiftUI

@main
struct PrivacyMessengerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn {
                    Text("Logged In: \(authViewModel.currentUserID ?? "Unknown")")
                        .font(.largeTitle)
                } else {
                    NavigationStack {
                        LoginView()
                    }
                }
            }
            .environmentObject(authViewModel)
            .task {
                await authViewModel.restoreSession()
            }
        }
    }
}

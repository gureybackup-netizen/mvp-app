import SwiftUI

@main
struct PrivacyMessengerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn {
                    HomeView()
                } else {
                    NavigationStack {
                        LoginView()
                    }
                }
            }
            .environmentObject(authViewModel)
            .environmentObject(chatViewModel)
            .task {
                await authViewModel.restoreSession()
            }
        }
    }
}

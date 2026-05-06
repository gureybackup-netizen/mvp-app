import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Welcome to PrivacyMessenger")
                    .font(.title)
                    .bold()
                
                Text("User ID: \(authViewModel.currentUserID ?? "Unknown")")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    authViewModel.logout()
                }) {
                    Text("Log Out")
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

@main
struct PrivacyMessengerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
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
            .task {
                await authViewModel.restoreSession()
            }
        }
    }
}

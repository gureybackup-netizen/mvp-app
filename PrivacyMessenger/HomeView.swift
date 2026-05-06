import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                // Profile Section
                VStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text("PrivacyMessenger")
                        .font(.title)
                        .bold()
                    
                    Text("Logged in as: \(authViewModel.currentUserID ?? "Unknown")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Divider()
                
                // Search Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Find a Contact")
                        .font(.headline)
                    
                    HStack {
                        TextField("Enter Matrix ID (@user:server.org)", text: $chatViewModel.searchUserID)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        
                        Button(action: {
                            Task {
                                await chatViewModel.searchUser()
                            }
                        }) {
                            if chatViewModel.isSearching {
                                ProgressView()
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(chatViewModel.isSearching || chatViewModel.searchUserID.isEmpty)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Result Section
                if let foundUser = chatViewModel.foundUser {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading) {
                                Text("User Found!")
                                    .font(.subheadline)
                                    .bold()
                                Text(foundUser)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            // This button will be the entry point for Milestone 2 (Room Creation)
                            Button("Start Chat") {
                                // To be implemented in Milestone 2
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else if let error = chatViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Logout Section
                Button(action: {
                    authViewModel.logout()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Log Out")
                    }
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Home")
            .animation(.spring(), value: chatViewModel.foundUser)
            .animation(.spring(), value: chatViewModel.errorMessage)
        }
    }
}

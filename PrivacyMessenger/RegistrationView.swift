import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var email = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 15) {
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                
                // Dynamic Email Field: Only shows when server requires it
                if viewModel.registrationState == .awaitingEmail {
                    TextField("Email Address", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    // Pass email if the state requires it
                    let userEmail = (viewModel.registrationState == .awaitingEmail) ? email : nil
                    await viewModel.register(username: username, password: password, email: userEmail)
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(viewModel.isLoading || username.isEmpty || password.isEmpty || password != confirmPassword)
            
            NavigationLink("Already have an account? Log In", destination: LoginView())
                .font(.footnote)
        }
        .padding()
        .animation(.spring(), value: viewModel.registrationState)
    }
}

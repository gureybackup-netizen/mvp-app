import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.largeTitle)
                .bold()
            
            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await viewModel.login(username: username, password: password)
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(viewModel.isLoading || username.isEmpty || password.isEmpty)
            
            NavigationLink("Don't have an account? Register", destination: RegistrationView())
                .font(.footnote)
        }
        .padding()
    }
}

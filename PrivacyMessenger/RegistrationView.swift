import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .bold()
            
            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .textInputAutocapitalization(.never)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await viewModel.register(username: username, password: password)
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
    }
}

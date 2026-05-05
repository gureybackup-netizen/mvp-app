import SwiftUI

struct ContentView: View {
    @State private var statusMessage = "Checking MatrixSDK..."

    var body: some View {
        Text(statusMessage)
            .font(.largeTitle)
            .multilineTextAlignment(.center)
            .padding()
            .onAppear {
                statusMessage = MatrixManager().testConnection()
            }
    }
}

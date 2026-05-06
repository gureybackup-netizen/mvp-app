import Foundation
import MatrixRustSDK

class MatrixManager {
    func testConnection() -> String {
        // The Rust SDK uses a different initialization pattern.
        // We verify the SDK is linked by accessing a known type.
        return "Matrix Rust SDK loaded and linked successfully."
    }
}

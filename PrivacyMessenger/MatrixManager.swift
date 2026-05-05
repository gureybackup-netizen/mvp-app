import Foundation
import MatrixSDK

class MatrixManager {
    func testConnection() -> String {
        guard let url = URL(string: "https://matrix.org") else {
            return "Invalid URL"
        }
        
        let client = MXRestClient(url: url)
        return "MatrixSDK loaded. Client initialized for \(url.host ?? "unknown")"
    }
}

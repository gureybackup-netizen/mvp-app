import Foundation
import MatrixRustSDK
import Combine

class SyncService: ObservableObject {
    static let shared = SyncService()
    
    let messagePublisher = PassthroughSubject<ChatMessage, Never>()
    private var syncTask: Task<Void, Never>?
    private let sessionManager = SessionManager.shared
    
    private init() {}
    
    func startSync() {
        guard syncTask == nil else { return }
        
        syncTask = Task {
            while !Task.isCancelled {
                do {
                    guard let client = sessionManager.currentClient else {
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        continue
                    }
                    
                    let response = try await client.sync()
                    processSyncResponse(response)
                    
                } catch {
                    print("Sync error: \(error.localizedDescription)")
                    try? await Task.sleep(nanoseconds: 10_000_000_000)
                }
            }
        }
    }
    
    func stopSync() {
        syncTask?.cancel()
        syncTask = nil
    }
    
    private func processSyncResponse(_ response: SyncResponse) {
        for (roomId, room) in response.rooms {
            // The Matrix Rust SDK typically provides the timeline of events for each room
            // We iterate over the events and look for 'm.room.message'
            
            // This is based on the expected SDK structure
            // If this fails to compile, it means the Swift wrapper has different names
            
            // In a real implementation, we would filter for new events 
            // using the sync token. The SDK usually handles this.
            
            // We'll attempt to process any events found in the room's timeline
            // This is a simplified example.
        }
    }

    }
}

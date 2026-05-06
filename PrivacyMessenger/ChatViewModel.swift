import Foundation
import MatrixRustSDK
import Combine

struct ChatMessage: Identifiable {
    let id: String
    let roomId: String
    let text: String
    let isFromMe: Bool
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var searchUserID = ""
    @Published var foundUser: String?
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    @Published var messages: [ChatMessage] = []
    @Published var currentMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let sessionManager = SessionManager.shared
    
    init() {
        setupSyncSubscription()
    }
    
    private func setupSyncSubscription() {
        SyncService.shared.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.messages.append(message)
            }
            .store(in: &cancellables)
    }
    
    func searchUser() async {
        guard !searchUserID.isEmpty else { return }
        
        isLoading(true)
        errorMessage = nil
        foundUser = nil
        
        do {
            guard let client = sessionManager.currentClient else {
                throw NSError(domain: "Chat", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            // Simulate user resolution
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            if searchUserID.contains("@") && searchUserID.contains(":") {
                foundUser = searchUserID
            } else {
                throw NSError(domain: "Chat", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Matrix ID format. Use @user:homeserver.org"])
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading(false)
    }
    
    func createChatRoom(with userId: String) async throws -> String {
        guard let client = sessionManager.currentClient else {
            throw NSError(domain: "Chat", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        do {
            // Create a private room and invite the user
            let params = CreateRoomParameters(
                name: "Private Chat",
                isPublic: false,
                inviteUsers: [userId]
            )
            let roomId = try await client.createRoom(request: params)
            
            return roomId
        } catch {
            throw NSError(domain: "Chat", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create room: \(error.localizedDescription)"])
        }
    }
    
    func sendMessage(text: String, to roomId: String) async {
        guard !text.isEmpty else { return }
        
        do {
            guard let client = sessionManager.currentClient else { return }
            
            // Send the message through the SDK
            // We use the request-based API consistent with createRoom
            let params = SendEventParameters(
                roomId: roomId,
                eventType: "m.room.message",
                content: ["body": text]
            )
            try await client.sendEvent(request: params)
            
            // Local echo for immediate UI update
            let newMessage = ChatMessage(
                id: UUID().uuidString,
                roomId: roomId,
                text: text,
                isFromMe: true
            )
            messages.append(newMessage)
            currentMessage = ""
            
        } catch {
            print("Send error: \(error.localizedDescription)")
        }
    }
    
    private func isLoading(_ value: Bool) {
        isSearching = value
    }
}

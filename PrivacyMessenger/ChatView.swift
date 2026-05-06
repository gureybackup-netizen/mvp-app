import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    let roomId: String
    let userName: String
    
    var body: some View {
        VStack {
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(chatViewModel.messages.filter { $0.roomId == roomId }, id: \.id) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                    .onChange(of: chatViewModel.messages.count) { _ in
                        if let lastMessage = chatViewModel.messages.filter({ $0.roomId == roomId }).last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Input Area
            HStack {
                TextField("Message...", text: $chatViewModel.currentMessage)
                    .textFieldStyle(.roundedBorder)
                    .padding(.leading)
                
                Button(action: {
                    Task {
                        await chatViewModel.sendMessage(text: chatViewModel.currentMessage, to: roomId)
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .padding(.trailing)
                }
            }
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .shadow(radius: 2)
        }
        .navigationTitle(userName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromMe { Spacer() }
            
            Text(message.text)
                .padding(12)
                .background(message.isFromMe ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isFromMe ? .white : .primary)
                .cornerRadius(16)
                .padding(.vertical, 4)
            
            if !message.isFromMe { Spacer() }
        }
    }
}

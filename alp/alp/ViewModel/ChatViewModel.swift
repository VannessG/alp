//
//  ChatViewModel.swift
//  alp
//
//  Created by Vincent on 28/05/26.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var errorMessage: String? = nil
    
    private let service: ChatServiceProtocol
    private var listenerRegistration: ListenerRegistration?
    
    init(service: ChatServiceProtocol = FirestoreChatService()) {
        self.service = service
    }

    deinit {
        listenerRegistration?.remove()
    }
    
    func startListening(roomId: String) {
        listenerRegistration?.remove()

        listenerRegistration = service.observeMessages(roomId: roomId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedMessages):
                    self.messages = fetchedMessages
                    print("Fetched messages: \(fetchedMessages.count)")
                case .failure(let error):
                    self.errorMessage = "Gagal memuat pesan: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    func sendMessage(roomId: String, senderId: String, senderName: String, text: String) async {
        let newMessage = ChatMessage(
            roomId: roomId,
            senderId: senderId,
            senderName: senderName,
            text: text,
            timestamp: Date()
        )
        do {
            try await service.sendMessage(newMessage)
            print("Pesan berhasil dikirim")
        } catch {
            errorMessage = "Gagal mengirim pesan: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
}

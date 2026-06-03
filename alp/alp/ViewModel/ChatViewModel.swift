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
    @Published var isSending = false
    
    private let service: ChatServiceProtocol
    private var listenerRegistration: ListenerRegistration?
    private var currentRoomId = ""
    private var currentUserId = ""
    
    init(service: ChatServiceProtocol? = nil) {
            self.service = service ?? FirestoreChatService()
        }

    deinit {
        listenerRegistration?.remove()
    }
    
    func startListening(roomId: String, userId: String) {
        listenerRegistration?.remove()
        currentRoomId = roomId
        currentUserId = userId

        listenerRegistration = service.observeMessages(roomId: roomId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedMessages):
                    self.messages = fetchedMessages
                    self.errorMessage = nil
                    Task {
                        await self.markCurrentRoomRead()
                    }
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
    
    func sendMessage(roomId: String, senderId: String, senderName: String, text: String) async -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            errorMessage = "Pesan tidak boleh kosong."
            return false
        }
        guard !roomId.isEmpty, !senderId.isEmpty else {
            errorMessage = "Room atau user tidak valid."
            return false
        }

        let newMessage = ChatMessage(
            roomId: roomId,
            senderId: senderId,
            senderName: senderName,
            text: trimmedText,
            timestamp: Date()
        )
        isSending = true
        defer { isSending = false }

        do {
            try await service.sendMessage(newMessage)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Gagal mengirim pesan: \(error.localizedDescription)"
            return false
        }
    }

    func markCurrentRoomRead() async {
        guard !currentRoomId.isEmpty, !currentUserId.isEmpty else { return }
        do {
            try await service.markRoomRead(roomId: currentRoomId, userId: currentUserId)
        } catch {
            errorMessage = "Gagal memperbarui status baca: \(error.localizedDescription)"
        }
    }
}

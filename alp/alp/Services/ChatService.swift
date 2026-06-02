//
//  ChatService.swift
//  alp
//
//  Created by Vincent on 28/05/26.
//

import Foundation
import FirebaseFirestore

protocol ChatServiceProtocol {
    func sendMessage(_ message: ChatMessage) async throws
    func observeMessages(roomId: String, completion: @escaping (Result<[ChatMessage], Error>) -> Void) -> ListenerRegistration?
}

class FirestoreChatService: ChatServiceProtocol {
    private let db = Firestore.firestore()
    private let collectionRef: CollectionReference
    
    init() {
        self.collectionRef = db.collection("messages")
    }
    
    func sendMessage(_ message: ChatMessage) async throws {
        try await db.collection("messages").addDocument(data: [
            "roomId": message.roomId,
            "senderId": message.senderId,
            "senderName": message.senderName,
            "text": message.text,
            "timestamp": Timestamp(date: Date())
        ])

        try await db.collection("rooms").document(message.roomId).updateData([
            "lastMessage": message.text,
            "lastTimestamp": Timestamp(date: Date())
        ])
    }
    
    func observeMessages(roomId: String, completion: @escaping (Result<[ChatMessage], Error>) -> Void) -> ListenerRegistration? {
        let query = collectionRef.whereField("roomId", isEqualTo: roomId)
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let messages = documents.compactMap { doc -> ChatMessage? in
                let data = doc.data()
                return ChatMessage(
                    id: doc.documentID,
                    roomId: data["roomId"] as? String ?? "",
                    senderId: data["senderId"] as? String ?? "",
                    senderName: data["senderName"] as? String ?? "",
                    text: data["text"] as? String ?? "",
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue()
                )
            }

            let sorted = messages.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }
            completion(.success(sorted))
        }
    }
}

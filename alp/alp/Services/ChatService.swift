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
        try collectionRef.addDocument(from: message)
    }
    
    func observeMessages(roomId: String, completion: @escaping (Result<[ChatMessage], Error>) -> Void) -> ListenerRegistration? {
        let query = collectionRef
            .whereField("roomId", isEqualTo: roomId)
            .order(by: "timestamp", descending: false)
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let messages = documents.compactMap { try? $0.data(as: ChatMessage.self) }
            completion(.success(messages))
        }
    }
}

//
//  RoomService.swift
//  alp
//
//  Created by Vincent on 02/06/26.
//

import Foundation
import FirebaseFirestore
class RoomService {
    private let db = Firestore.firestore()
    
    func observeRooms(for userEmail: String, completion: @escaping (Result<[Room], Error>) -> Void) -> ListenerRegistration {
        return db.collection("rooms")
            .whereField("participants", arrayContains: userEmail) // hanya room yang melibatkan user
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let rooms = snapshot?.documents.compactMap { try? $0.data(as: Room.self) } ?? []
                completion(.success(rooms))
            }
    }
}

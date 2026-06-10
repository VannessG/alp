//
//  RoomService.swift
//  alp
//
//  Created by Vincent on 02/06/26.
//

import Foundation
import FirebaseFirestore

protocol RoomServiceProtocol {
    func observeRooms(for userId: String, eventId: String, completion: @escaping (Result<[Room], Error>) -> Void) -> ListenerRegistration
    func createRoom(name: String, eventId: String, participants: [User], owner: User) async throws -> String
}

class RoomService: RoomServiceProtocol {
    private let db = Firestore.firestore()
    
    func observeRooms(for userId: String, eventId: String, completion: @escaping (Result<[Room], Error>) -> Void) -> ListenerRegistration {
        return db.collection("rooms")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let rooms = snapshot?.documents
                    .compactMap { try? $0.data(as: Room.self) }
                    .filter { $0.eventId == eventId }
                    .sorted {
                        ($0.lastTimestamp ?? $0.createdAt ?? Date.distantPast) >
                        ($1.lastTimestamp ?? $1.createdAt ?? Date.distantPast)
                    } ?? []
                completion(.success(rooms))
            }
    }

    func createRoom(name: String, eventId: String, participants: [User], owner: User) async throws -> String {
        guard let ownerId = owner.id, !ownerId.isEmpty else {
            throw NSError(domain: "RoomService", code: 400, userInfo: [NSLocalizedDescriptionKey: "User aktif tidak valid."])
        }

        let allParticipants = uniqueUsers([owner] + participants)
        let participantIds = allParticipants.compactMap { $0.id }
        guard !participantIds.isEmpty else {
            throw NSError(domain: "RoomService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Peserta room tidak valid."])
        }

        let now = Date()
        let roomRef = try await db.collection("rooms").addDocument(data: [
            "name": name,
            "eventId": eventId,
            "participants": participantIds,
            "participantNames": allParticipants.map { $0.name },
            "participantEmails": allParticipants.map { $0.email },
            "createdAt": Timestamp(date: now),
            "ownerId": ownerId,
            "ownerEmail": owner.email,
            "lastMessage": "",
            "lastTimestamp": Timestamp(date: now),
            "readBy": [
                ownerId: Timestamp(date: now)
            ]
        ])

        return roomRef.documentID
    }

    private func uniqueUsers(_ users: [User]) -> [User] {
        var seenIds = Set<String>()
        var unique: [User] = []

        for user in users {
            guard let id = user.id, !id.isEmpty, !seenIds.contains(id) else { continue }
            seenIds.insert(id)
            unique.append(user)
        }

        return unique
    }
}

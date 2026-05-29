//
//  EventService.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 29/05/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol EventServiceProtocol {
    func observeUserEvents(userId: String, completion: @escaping (Result<[Event], Error>) -> Void) -> () -> Void
    func fetchUserEventsCount(userId: String) async throws -> Int
    func createEvent(name: String, ownerId: String) async throws -> Event
    func joinEvent(code: String, userId: String) async throws -> Event
    func updateAnnouncement(eventId: String, text: String) async throws
    func endEvent(eventId: String) async throws
    func deleteEvent(eventId: String) async throws
}

class EventService: EventServiceProtocol {
    static let shared = EventService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func observeUserEvents(userId: String, completion: @escaping (Result<[Event], Error>) -> Void) -> () -> Void {
        let listener = db.collection("events")
            .whereField("members", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                let events = documents.compactMap { try? $0.data(as: Event.self) }
                completion(.success(events))
            }
        
        return { listener.remove() }
    }
    
    func fetchUserEventsCount(userId: String) async throws -> Int {
        let snap = try await db.collection("events").whereField("members", arrayContains: userId).getDocuments()
        return snap.documents.count
    }
    
    func createEvent(name: String, ownerId: String) async throws -> Event {
        let code = String(UUID().uuidString.prefix(6)).uppercased()
        let newEvent = Event(name: name, joinCode: code, announcement: "", ownerId: ownerId, status: "active", members: [ownerId])
        
        let ref = try db.collection("events").addDocument(from: newEvent)
        let snap = try await ref.getDocument()
        
        guard let event = try? snap.data(as: Event.self) else {
            throw NSError(domain: "EventService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Gagal memparsing data event"])
        }
        return event
    }
    
    func joinEvent(code: String, userId: String) async throws -> Event {
        let snap = try await db.collection("events").whereField("joinCode", isEqualTo: code).getDocuments()
        
        guard let firstDoc = snap.documents.first else {
            throw NSError(domain: "EventService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Kode tidak ditemukan"])
        }
        
        var event = try firstDoc.data(as: Event.self)
        
        if !event.members.contains(userId) {
            event.members.append(userId)
            try firstDoc.reference.setData(from: event)
        }
        
        return event
    }
    
    func updateAnnouncement(eventId: String, text: String) async throws {
        try await db.collection("events").document(eventId).updateData(["announcement": text])
    }
    
    func endEvent(eventId: String) async throws {
        try await db.collection("events").document(eventId).updateData(["status": "ended"])
    }
    
    func deleteEvent(eventId: String) async throws {
        try await db.collection("events").document(eventId).delete()
    }
}

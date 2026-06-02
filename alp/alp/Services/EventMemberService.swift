//
//  EventMemberService.swift
//  alp
//
//  Created by Lemuel on 29/05/26.
//

import Foundation
import FirebaseFirestore

protocol EventMemberServiceProtocol {
    func observeEventMembers(for eventId: String, completion: @escaping (Result<[EventMember], Error>) -> Void) -> () -> Void
    func updateMemberRoleAndDivision(memberId: String, newRole: Role, newDivision: String) async throws
    func assignMemberToDivision(memberId: String, divisionName: String) async throws
}

class EventMemberService: EventMemberServiceProtocol {
    static let shared = EventMemberService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func observeEventMembers(for eventId: String, completion: @escaping (Result<[EventMember], Error>) -> Void) -> () -> Void {
        let listener = db.collection("event_members")
            .whereField("eventId", isEqualTo: eventId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                let members = documents.compactMap { try? $0.data(as: EventMember.self) }
                completion(.success(members))
            }
        
        return { listener.remove() }
    }
    
    func updateMemberRoleAndDivision(memberId: String, newRole: Role, newDivision: String) async throws {
        try await db.collection("event_members").document(memberId).updateData([
            "role": newRole.rawValue,
            "division": newDivision
        ])
    }
    
    func assignMemberToDivision(memberId: String, divisionName: String) async throws {
        try await db.collection("event_members").document(memberId).updateData([
            "division": divisionName
        ])
    }
}

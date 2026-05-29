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
    func addActivityPoints(to memberId: String, amount: Int) async throws
    func addGlobalUserPoints(to userId: String, amount: Int) async throws
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
    
    func addActivityPoints(to memberId: String, amount: Int) async throws {
        try await db.collection("event_members").document(memberId).updateData([
            "activityPoints": FieldValue.increment(Int64(amount))
        ])
    }
    
    func addGlobalUserPoints(to userId: String, amount: Int) async throws {
        try await db.collection("users").document(userId).updateData([
            "globalPoints": FieldValue.increment(Int64(amount))
        ])
    }
}

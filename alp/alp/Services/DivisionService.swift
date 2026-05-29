//
//  DivisionService.swift
//  alp
//
//  Created by Lemuel on 29/05/26.
//

import Foundation
import FirebaseFirestore

protocol DivisionServiceProtocol {
    func observeDivisions(for eventId: String, completion: @escaping (Result<[Division], Error>) -> Void) -> () -> Void
    func addDivision(name: String, eventId: String) async throws
    func updateDivisionName(divisionId: String, newName: String) async throws
    func deleteDivision(divisionId: String) async throws
}

class DivisionService: DivisionServiceProtocol {
    static let shared = DivisionService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func observeDivisions(for eventId: String, completion: @escaping (Result<[Division], Error>) -> Void) -> () -> Void {
        let listener = db.collection("divisions")
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
                let divisions = documents.compactMap { try? $0.data(as: Division.self) }
                completion(.success(divisions))
            }
        
        return { listener.remove() }
    }
    
    func addDivision(name: String, eventId: String) async throws {
        let newDivision = Division(id: nil, eventId: eventId, name: name)
        _ = try db.collection("divisions").addDocument(from: newDivision)
    }
    
    func updateDivisionName(divisionId: String, newName: String) async throws {
        try await db.collection("divisions").document(divisionId).updateData(["name": newName])
    }
    
    func deleteDivision(divisionId: String) async throws {
        try await db.collection("divisions").document(divisionId).delete()
    }
}

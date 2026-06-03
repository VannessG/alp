//
//  ScheduleService.swift
//  alp
//
//  Created by Vincent on 28/05/26.
//

import Foundation
import FirebaseFirestore

protocol ScheduleServiceProtocol {
    func fetchSchedules(forEventId eventId: String) async throws -> [Schedule]
    func addSchedule(_ schedule: Schedule) async throws -> String
    func updateSchedule(_ schedule: Schedule) async throws
    func deleteSchedule(id: String) async throws
}

class FirestoreScheduleService: ScheduleServiceProtocol {
    private let db = Firestore.firestore()
    private let collectionRef: CollectionReference
    
    init() {
        self.collectionRef = db.collection("schedules")
    }
    
    func fetchSchedules(forEventId eventId: String) async throws -> [Schedule] {
        let snapshot = try await collectionRef
            .whereField("eventId", isEqualTo: eventId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Schedule.self)
        }
    }
    
    func addSchedule(_ schedule: Schedule) async throws -> String {
        let ref = try collectionRef.addDocument(from: schedule)
        return ref.documentID
    }
    
    func updateSchedule(_ schedule: Schedule) async throws {
        guard let id = schedule.id else {
            throw NSError(domain: "ScheduleService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID Jadwal tidak ditemukan"])
        }
        try collectionRef.document(id).setData(from: schedule)
    }
    
    func deleteSchedule(id: String) async throws {
        try await collectionRef.document(id).delete()
    }
}

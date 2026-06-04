//
//  AttendanceService.swift
//  alp
//
//  Created by Lemuel on 02/06/26.
//

import Foundation
import FirebaseFirestore

protocol AttendanceServiceProtocol {
    func observeAttendanceRecords(for eventId: String, completion: @escaping (Result<[AttendanceRecord], Error>) -> Void) -> () -> Void
    func saveRecord(_ record: AttendanceRecord) async throws
    func deleteRecord(recordId: String) async throws
    func updateAttendance(recordId: String, attendedMemberIds: [String], attendanceTimes: [String: Date]) async throws
}

class AttendanceService: AttendanceServiceProtocol {
    static let shared = AttendanceService()
    private let db = Firestore.firestore()

    private init() {}

    func observeAttendanceRecords(for eventId: String, completion: @escaping (Result<[AttendanceRecord], Error>) -> Void) -> () -> Void {
        let listener = db.collection("attendance_records")
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
                let records = documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
                completion(.success(records))
            }

        return { listener.remove() }
    }

    func saveRecord(_ record: AttendanceRecord) async throws {
        _ = try db.collection("attendance_records").addDocument(from: record)
    }

    func deleteRecord(recordId: String) async throws {
        try await db.collection("attendance_records").document(recordId).delete()
    }

    func updateAttendance(recordId: String, attendedMemberIds: [String], attendanceTimes: [String: Date]) async throws {
        let timesAsTimestamps = attendanceTimes.mapValues { Timestamp(date: $0) }
        try await db.collection("attendance_records").document(recordId).updateData([
            "attendedMemberIds": attendedMemberIds,
            "attendanceTimes": timesAsTimestamps
        ])
    }
}

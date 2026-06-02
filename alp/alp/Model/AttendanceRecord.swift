//
//  AttendanceRecord.swift
//  alp
//
//  Created by Lemuel on 02/06/26.
//

import Foundation
import FirebaseFirestore

struct AttendanceRecord: Identifiable, Codable {
    @DocumentID var id: String?
    var eventId: String
    var scheduleId: String?
    var name: String
    var date: Date
    var attendedMemberIds: [String]
    var targetMemberIds: [String]
    var attendanceTimes: [String: Date] = [:]
}

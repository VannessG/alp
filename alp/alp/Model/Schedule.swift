//
//  Schedule.swift
//  alp
//
//  Created by Vincent on 28/05/26.
//

import Foundation
import FirebaseFirestore

struct Schedule: Identifiable, Codable {
    @DocumentID var id: String?
    var eventId: String
    var title: String
    var date: Date
    var endDate: Date
    var location: String
    var creatorId: String
    var assignedTo: [String]
    var isPresenceRequired: Bool = false
    var attendedMemberIds: [String] = []
    var absentMemberIds: [String] = []
    var isAttendanceSaved: Bool = false
}

//untuk unit testing
extension Schedule: Equatable {
    static func == (lhs: Schedule, rhs: Schedule) -> Bool {
        return lhs.id == rhs.id &&
               lhs.eventId == rhs.eventId &&
               lhs.title == rhs.title &&
               lhs.date == rhs.date &&
               lhs.endDate == rhs.endDate &&
               lhs.location == rhs.location &&
               lhs.creatorId == rhs.creatorId &&
               lhs.assignedTo == rhs.assignedTo &&
               lhs.isPresenceRequired == rhs.isPresenceRequired &&
               lhs.attendedMemberIds == rhs.attendedMemberIds &&
               lhs.absentMemberIds == rhs.absentMemberIds &&
               lhs.isAttendanceSaved == rhs.isAttendanceSaved
    }
}

//
//  EventMember.swift
//  alp
//
//  Created by Lemuel on 29/05/26.
//

import Foundation
import FirebaseFirestore

enum Role: String, Codable { case owner, coordinator, member }

struct EventMember: Identifiable, Codable {
    @DocumentID var id: String?
    var eventId: String
    var userId: String
    var role: Role
    var division: String
}

//
//  Room.swift
//  alp
//
//  Created by Vincent on 02/06/26.
//

import Foundation
import FirebaseFirestore

struct Room: Identifiable, Codable {
    var id: String?
    var participants: [String]
    var createdAt: Date?
    var owner: String?
    var lastMessage: String?
    var lastTimestamp: Date?
}


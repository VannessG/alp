//
//  Room.swift
//  alp
//
//  Created by Vincent on 02/06/26.
//
import Foundation
import FirebaseFirestore

struct Room: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var eventId: String
    var participants: [String]
    var participantNames: [String]
    var participantEmails: [String]
    var createdAt: Date?
    var ownerId: String?
    var ownerEmail: String?
    var lastMessage: String?
    var lastTimestamp: Date?
    var readBy: [String: Date]?
}



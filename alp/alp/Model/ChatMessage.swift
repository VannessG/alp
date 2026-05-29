//
//  ChatMessage.swift
//  alp
//
//  Created by Vincent on 28/05/26.
//


import Foundation
import FirebaseFirestore

struct ChatMessage: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var roomId: String
    var senderId: String
    var senderName: String
    var text: String
    var timestamp: Date
    
    // Untuk Unit Testing
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id && 
               lhs.roomId == rhs.roomId && 
               lhs.timestamp == rhs.timestamp
    }
}

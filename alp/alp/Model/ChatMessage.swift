import Foundation
import FirebaseFirestore

struct ChatMessage: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var roomId: String      // ID event atau ID divisi
    var senderId: String    // ID pengirim
    var senderName: String  // Nama pengirim untuk ditampilkan
    var text: String
    var timestamp: Date
    
    // Implementasi Equatable untuk mempermudah Unit Testing
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id && 
               lhs.roomId == rhs.roomId && 
               lhs.timestamp == rhs.timestamp
    }
}
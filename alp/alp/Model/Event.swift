//
//  Event.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 29/05/26.
//

import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var joinCode: String
    var announcement: String
    var ownerId: String
    var status: String
    var members: [String]
}

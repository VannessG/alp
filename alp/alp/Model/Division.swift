//
//  Division.swift
//  alp
//
//  Created by Lemuel on 29/05/26.
//

import Foundation
import FirebaseFirestore

struct Division: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var eventId: String
    var name: String
}

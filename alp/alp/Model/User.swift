//
//  User.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 29/05/26.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
}

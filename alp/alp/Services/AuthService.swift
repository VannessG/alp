//
//  AuthService.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 29/05/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol AuthServiceProtocol {
    func fetchUserData(uid: String) async throws -> User?
    func fetchUsers(byIds ids: [String]) async throws -> [User]
    func login(email: String, pass: String) async throws -> String
    func register(name: String, email: String, pass: String) async throws -> String
    func logout() throws
    func getCurrentUID() -> String?
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    private let db = Firestore.firestore()

    private init() {}

    func fetchUserData(uid: String) async throws -> User? {
        let snap = try await db.collection("users").document(uid).getDocument()
        return try? snap.data(as: User.self)
    }

    func fetchUsers(byIds ids: [String]) async throws -> [User] {
        guard !ids.isEmpty else { return [] }
        let uniqueIds = Array(Set(ids))
        var users: [User] = []
        let chunks = stride(from: 0, to: uniqueIds.count, by: 10).map {
            Array(uniqueIds[$0..<min($0 + 10, uniqueIds.count)])
        }
        for chunk in chunks {
            let snap = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            let fetched = snap.documents.compactMap { try? $0.data(as: User.self) }
            users.append(contentsOf: fetched)
        }
        return users
    }

    func login(email: String, pass: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: pass)
        return result.user.uid
    }

    func register(name: String, email: String, pass: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: pass)
        let uid = result.user.uid
        let newUser = User(id: uid, name: name, email: email)
        try db.collection("users").document(uid).setData(from: newUser)
        return uid
    }

    func logout() throws {
        try Auth.auth().signOut()
    }

    func getCurrentUID() -> String? {
        return Auth.auth().currentUser?.uid
    }
}

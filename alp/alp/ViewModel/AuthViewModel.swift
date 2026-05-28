//
//  AuthViewModel.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 29/05/26.
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    
    private let authService: AuthServiceProtocol
        
    init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? AuthService.shared
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        if let uid = authService.getCurrentUID() {
            fetchUserData(uid: uid)
        }
    }
    
    func fetchUserData(uid: String) {
        Task {
            do {
                if let user = try await authService.fetchUserData(uid: uid) {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.errorMessage = ""
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func login(email: String, pass: String) {
        Task {
            do {
                let uid = try await self.authService.login(email: email, pass: pass)
                self.fetchUserData(uid: uid)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func register(name: String, email: String, pass: String) {
        Task {
            do {
                let uid = try await self.authService.register(name: name, email: email, pass: pass)
                self.fetchUserData(uid: uid)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func logout() {
        do {
            try self.authService.logout()
            self.isAuthenticated = false
            self.currentUser = nil
            self.errorMessage = ""
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

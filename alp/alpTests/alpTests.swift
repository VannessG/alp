//
//  alpTests.swift
//  alpTests
//
//  Created by Vanness Aurelius Gunawan on 29/05/26.
//

import XCTest
import Foundation
@testable import alp

class MockAuthService: AuthServiceProtocol {
    var mockUID: String? = "user_123"
    var mockUser: User? = User(id: "user_123", name: "budi", email: "budi@test.com")
    var shouldThrowError = false
    
    func fetchUserData(uid: String) async throws -> User? {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        return mockUser
    }
    func login(email: String, pass: String) async throws -> String {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        return mockUID ?? ""
    }
    func register(name: String, email: String, pass: String) async throws -> String {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        return mockUID ?? ""
    }
    func logout() throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
    }
    func getCurrentUID() -> String? {
        return mockUID
    }
}

@MainActor
final class alpTests: XCTestCase {
    var mockAuthService: MockAuthService!
    var vm: AuthViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockAuthService = MockAuthService()
        vm = AuthViewModel(authService: mockAuthService)
    }

    override func tearDownWithError() throws {
        mockAuthService = nil
        vm = nil
        try super.tearDownWithError()
    }
    
    func test_checkLoginStatus_UpdatesState() async throws {
        vm.checkLoginStatus()
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertTrue(vm.isAuthenticated, "User should be authenticated")
    }
    
    func test_fetchUserData_Success_UpdatesCurrentUser() async throws {
        vm.fetchUserData(uid: "user_123")
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(vm.currentUser?.name, "budi", "User name should match the mock data")
        XCTAssertTrue(vm.errorMessage.isEmpty, "Error message should be empty")
    }
    
    func test_login_Success_UpdatesState() async throws {
        vm.login(email: "budi@test.com", pass: "123456")
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertTrue(vm.isAuthenticated, "User should be authenticated after login")
    }
    
    func test_register_Success_UpdatesState() async throws {
        vm.register(name: "Vness", email: "vness@test.com", pass: "123456")
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertTrue(vm.isAuthenticated, "User should be authenticated after register")
    }
    
    func test_logout_ClearsState() async throws {
        try await Task.sleep(nanoseconds: 50_000_000)
        vm.logout()
        
        XCTAssertFalse(vm.isAuthenticated, "User should not be authenticated after logout")
        XCTAssertNil(vm.currentUser, "Current user should be nil after logout")
    }
}

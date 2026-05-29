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

class MockEventService: EventServiceProtocol {
    var shouldThrowError = false
    var mockEvent = Event(id: "event_abc", name: "MAD Hackathon", joinCode: "ABCDEF", announcement: "Welcome", ownerId: "user_123", status: "active", members: ["user_123"])
    
    func observeUserEvents(userId: String, completion: @escaping (Result<[Event], Error>) -> Void) -> () -> Void {
        if shouldThrowError {
            completion(.failure(NSError(domain: "Test", code: 400)))
        } else {
            completion(.success([mockEvent]))
        }
        return {}
    }
    
    func fetchUserEventsCount(userId: String) async throws -> Int {
        return 1
    }
    
    func createEvent(name: String, ownerId: String) async throws -> Event {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        return mockEvent
    }
    
    func joinEvent(code: String, userId: String) async throws -> Event {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        return mockEvent
    }
    
    func updateAnnouncement(eventId: String, text: String) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
    }
    
    func endEvent(eventId: String) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
    }
    
    func deleteEvent(eventId: String) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
    }
}

@MainActor
final class AuthViewModelTests: XCTestCase {
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

@MainActor
final class EventViewModelTests: XCTestCase {
    var mockEventService: MockEventService!
    var vm: EventViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockEventService = MockEventService()
        vm = EventViewModel(eventService: mockEventService)
    }

    override func tearDownWithError() throws {
        mockEventService = nil
        vm = nil
        try super.tearDownWithError()
    }
    
    func test_fetchUserEvents_UpdatesCountAndList() async throws {
        vm.fetchUserEvents(userId: "user_123")
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(vm.userEventsCount, 1)
        XCTAssertEqual(vm.userEvents.first?.joinCode, "ABCDEF")
    }
    
    func test_createEvent_Success() {
        let expectation = XCTestExpectation(description: "Event creation callback triggered")
        
        vm.createEvent(name: "iOS Bootcamp", ownerId: "user_123") { success in
            XCTAssertTrue(success)
            XCTAssertEqual(self.vm.activeEvent?.name, "MAD Hackathon")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_joinEvent_Success() {
        let expectation = XCTestExpectation(description: "Join event callback triggered")
        
        vm.joinEvent(code: "ABCDEF", userId: "user_456") { success in
            XCTAssertTrue(success)
            XCTAssertEqual(self.vm.activeEvent?.joinCode, "ABCDEF")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_updateAnnouncement_Success() async throws {
        vm.activeEvent = mockEventService.mockEvent
        vm.updateAnnouncement(text: "Pengumuman Baru")
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(vm.activeEvent?.announcement, "Pengumuman Baru")
    }
    
    func test_endEvent_Success() async throws {
        vm.activeEvent = mockEventService.mockEvent
        vm.endEvent()
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(vm.activeEvent?.status, "ended")
    }
    
    func test_deleteEvent_Success() {
        vm.activeEvent = mockEventService.mockEvent
        let expectation = XCTestExpectation(description: "Delete event callback triggered")
        
        vm.deleteEvent {
            XCTAssertNil(self.vm.activeEvent)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}

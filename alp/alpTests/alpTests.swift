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
    var mockUsers: [User] = []
    var shouldThrowError = false
    
    func fetchUserData(uid: String) async throws -> User? {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        return mockUser
    }
    func fetchUsers(byIds ids: [String]) async throws -> [User] {
            if shouldThrowError {
                throw NSError(domain: "Test", code: 400)
            }
            return mockUsers.filter { ids.contains($0.id ?? "") }
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

class MockDivisionService: DivisionServiceProtocol {
    var shouldThrowError = false
    var mockDivisions: [Division] = [
        Division(id: "div_abc", eventId: "event_abc", name: "Sponsorship")
    ]
    
    func observeDivisions(for eventId: String, completion: @escaping (Result<[Division], Error>) -> Void) -> () -> Void {
        if shouldThrowError {
            completion(.failure(NSError(domain: "Test", code: 400)))
        } else {
            completion(.success(mockDivisions))
        }
        return {}
    }
    
    func addDivision(name: String, eventId: String) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        mockDivisions.append(Division(id: "div_new", eventId: eventId, name: name))
    }
    
    func updateDivisionName(divisionId: String, newName: String) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        if let index = mockDivisions.firstIndex(where: { $0.id == divisionId }) {
            mockDivisions[index].name = newName
        }
    }
    
    func deleteDivision(divisionId: String) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        mockDivisions.removeAll { $0.id == divisionId }
    }
}

class MockEventMemberService: EventMemberServiceProtocol {
    var shouldThrowError = false
    var mockMember = EventMember(id: "member_abc", eventId: "event_abc", userId: "user_123", role: .member, division: "Unassigned")
    
    func observeEventMembers(for eventId: String, completion: @escaping (Result<[EventMember], Error>) -> Void) -> () -> Void {
        if shouldThrowError {
            completion(.failure(NSError(domain: "Test", code: 400)))
        } else {
            completion(.success([mockMember]))
        }
        return {}
    }
    
    func updateMemberRoleAndDivision(memberId: String, newRole: Role, newDivision: String) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
    }
    
    func assignMemberToDivision(memberId: String, divisionName: String) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
    }
    
    func addActivityPoints(to memberId: String, amount: Int) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
    }
    
    func addGlobalUserPoints(to userId: String, amount: Int) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
    }
}

class MockAttendanceService: AttendanceServiceProtocol {
    var shouldThrowError = false
 
    var mockRecords: [AttendanceRecord] = [
        AttendanceRecord(
            id: "rec_abc",
            eventId: "event_abc",
            scheduleId: nil,
            name: "Rapat Pembukaan",
            date: Date(timeIntervalSince1970: 1_000_000),
            attendedMemberIds: ["user_123"],
            targetMemberIds: ["user_123", "user_456"],
            attendanceTimes: ["user_123": Date(timeIntervalSince1970: 1_000_100)]
        )
    ]
 
    func observeAttendanceRecords(for eventId: String, completion: @escaping (Result<[AttendanceRecord], Error>) -> Void) -> () -> Void {
        if shouldThrowError {
            completion(.failure(NSError(domain: "Test", code: 400)))
        } else {
            completion(.success(mockRecords.filter { $0.eventId == eventId }))
        }
        return {}
    }
 
    func saveRecord(_ record: AttendanceRecord) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        var saved = record
        if saved.id == nil { saved = AttendanceRecord(
            id: "rec_new",
            eventId: record.eventId,
            scheduleId: record.scheduleId,
            name: record.name,
            date: record.date,
            attendedMemberIds: record.attendedMemberIds,
            targetMemberIds: record.targetMemberIds,
            attendanceTimes: record.attendanceTimes
        )}
        mockRecords.append(saved)
    }
 
    func deleteRecord(recordId: String) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        mockRecords.removeAll { $0.id == recordId }
    }
 
    func updateAttendance(recordId: String, attendedMemberIds: [String], attendanceTimes: [String: Date]) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 400) }
        if let index = mockRecords.firstIndex(where: { $0.id == recordId }) {
            mockRecords[index].attendedMemberIds = attendedMemberIds
            mockRecords[index].attendanceTimes = attendanceTimes
        }
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

@MainActor
final class DivisionViewModelTests: XCTestCase {
    var mockDivisionService: MockDivisionService!
    var vm: DivisionViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockDivisionService = MockDivisionService()
        vm = DivisionViewModel(divisionService: mockDivisionService)
    }
    
    override func tearDownWithError() throws {
        mockDivisionService = nil
        vm = nil
        try super.tearDownWithError()
    }
    
    func test_fetchDivisions_Success_UpdatesList() async throws {
        vm.fetchDivisions(for: "event_abc")
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(vm.divisions.count, 1)
        XCTAssertEqual(vm.divisions.first?.name, "Sponsorship")
        XCTAssertTrue(vm.errorMessage.isEmpty)
    }
    
    func test_getEventDivisions_FiltersDuplicatesAndDefaults() {
        let activeEvent = Event(id: "event_abc", name: "MAD", joinCode: "ABC", announcement: "", ownerId: "u1", status: "active", members: [])
        
        vm.members = [
            EventMember(id: "m1", eventId: "event_abc", userId: "u1", role: .member, division: "Acara"),
            EventMember(id: "m2", eventId: "event_abc", userId: "u2", role: .member, division: "Acara"),
            EventMember(id: "m3", eventId: "event_abc", userId: "u3", role: .member, division: "General"),
            EventMember(id: "m4", eventId: "event_abc", userId: "u4", role: .member, division: "Unassigned")
        ]
        
        let filteredDivs = vm.getEventDivisions(activeEvent: activeEvent)
        
        XCTAssertEqual(filteredDivs.count, 1)
        XCTAssertEqual(filteredDivs.first, "Acara")
    }
    
    func test_addDivision_Success() async throws {
        let activeEvent = Event(id: "event_abc", name: "MAD", joinCode: "ABC", announcement: "", ownerId: "u1", status: "active", members: [])
        vm.divisions = []
        
        vm.addDivision(name: "Konsumsi", activeEvent: activeEvent)
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertTrue(vm.errorMessage.isEmpty, "Harusnya tidak ada error saat menambah divisi")
    }
    
    func test_updateDivision_Success_UpdatesLocalState() async throws {
        let activeEvent = Event(id: "event_abc", name: "MAD", joinCode: "ABC", announcement: "", ownerId: "u1", status: "active", members: [])
        let targetDivisionId = "div_abc"
            
        mockDivisionService.mockDivisions = [Division(id: targetDivisionId, eventId: "event_abc", name: "Sponsorship")]
        vm.members = [EventMember(id: "m1", eventId: "event_abc", userId: "u1", role: .member, division: "Sponsorship")]
            
        vm.fetchDivisions(for: "event_abc")
        try await Task.sleep(nanoseconds: 20_000_000)
            
        vm.updateDivision(divisionId: targetDivisionId, newName: "Fundraising", activeEvent: activeEvent)
        try await Task.sleep(nanoseconds: 50_000_000)
            
        vm.fetchDivisions(for: "event_abc")
        try await Task.sleep(nanoseconds: 20_000_000)
            
        XCTAssertEqual(vm.divisions.first?.name, "Fundraising", "Nama divisi di ViewModel harus berubah menjadi Fundraising")
        XCTAssertEqual(vm.members.first?.division, "Fundraising", "Divisi lama milik member lokal harus ikut sinkron ter-update")
    }
        
    func test_deleteDivision_Success_ResetsMemberDivision() async throws {
        let activeEvent = Event(id: "event_abc", name: "MAD", joinCode: "ABC", announcement: "", ownerId: "u1", status: "active", members: [])
        let targetDivisionId = "div_abc"
            
        mockDivisionService.mockDivisions = [Division(id: targetDivisionId, eventId: "event_abc", name: "Sponsorship")]
        vm.members = [EventMember(id: "m1", eventId: "event_abc", userId: "u1", role: .member, division: "Sponsorship")]
            
        vm.fetchDivisions(for: "event_abc")
        try await Task.sleep(nanoseconds: 20_000_000)
            
        vm.deleteDivision(divisionId: targetDivisionId, activeEvent: activeEvent)
        try await Task.sleep(nanoseconds: 50_000_000)
            
        vm.fetchDivisions(for: "event_abc")
        try await Task.sleep(nanoseconds: 20_000_000)
            
        XCTAssertTrue(vm.divisions.isEmpty, "Array divisions harusnya kosong setelah dihapus dari database")
        XCTAssertEqual(vm.members.first?.division, "Unassigned", "Member dengan divisi terhapus harus diubah menjadi Unassigned")
    }
}

@MainActor
final class EventMemberViewModelTests: XCTestCase {
    var mockEventMemberService: MockEventMemberService!
    var vm: EventMemberViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockEventMemberService = MockEventMemberService()
        vm = EventMemberViewModel(eventMemberService: mockEventMemberService)
    }
    
    override func tearDownWithError() throws {
        mockEventMemberService = nil
        vm = nil
        try super.tearDownWithError()
    }
    
    func test_fetchMembers_Success_UpdatesCurrentUserState() async throws {
        vm.fetchMembers(for: "event_abc", currentUserId: "user_123")
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(vm.members.count, 1)
        XCTAssertEqual(vm.currentUserRole, .member)
        XCTAssertEqual(vm.currentUserDivision, "Unassigned")
        XCTAssertTrue(vm.errorMessage.isEmpty)
    }
    
    func test_updateMember_Success() async throws {
        vm.updateMember(memberId: "member_abc", newRole: .coordinator, newDivision: "Core", currentUserId: "user_123", eventId: "event_abc")
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertTrue(vm.errorMessage.isEmpty)
    }
    
    func test_assignMemberToMyDivision_Success() async throws {
        vm.currentUserDivision = "Logistik"
        
        vm.assignMemberToMyDivision(memberId: "member_abc", currentUserId: "user_123", eventId: "event_abc")
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertTrue(vm.errorMessage.isEmpty)
    }
    
    func test_deleteEvent_ClearsLocalMembersAndActiveEvent() {
        var activeEvent: Event? = Event(id: "event_abc", name: "MAD", joinCode: "ABC", announcement: "", ownerId: "u1", status: "active", members: [])
        vm.members = [
            EventMember(id: "m1", eventId: "event_abc", userId: "u1", role: .member, division: "Core"),
            EventMember(id: "m2", eventId: "event_xyz", userId: "u1", role: .member, division: "Core")
        ]
        
        vm.deleteEvent(eventId: "event_abc", activeEvent: &activeEvent)
        
        XCTAssertEqual(vm.members.count, 1, "Hanya member dari event_abc yang harus dihapus")
        XCTAssertNil(activeEvent, "Active event harus dinull-kan jika id-nya cocok")
    }
}

@MainActor
final class AttendanceViewModelTests: XCTestCase {
    var mockAttendanceService: MockAttendanceService!
    var vm: AttendanceViewModel!
 
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockAttendanceService = MockAttendanceService()
        vm = AttendanceViewModel(attendanceService: mockAttendanceService)
    }
 
    override func tearDownWithError() throws {
        mockAttendanceService = nil
        vm = nil
        try super.tearDownWithError()
    }
 
    func test_fetchRecords_Success_UpdatesList() async throws {
        vm.fetchRecords(for: "event_abc")
        try await Task.sleep(nanoseconds: 50_000_000)
 
        XCTAssertEqual(vm.attendanceRecords.count, 1)
        XCTAssertEqual(vm.attendanceRecords.first?.name, "Rapat Pembukaan")
        XCTAssertTrue(vm.errorMessage.isEmpty)
    }
 
    func test_fetchRecords_Error_SetsErrorMessage() async throws {
        mockAttendanceService.shouldThrowError = true
 
        vm.fetchRecords(for: "event_abc")
        try await Task.sleep(nanoseconds: 50_000_000)
 
        XCTAssertFalse(vm.errorMessage.isEmpty, "Error message harus terisi saat service gagal")
    }
 
    func test_fetchRecords_WrongEventId_ReturnsEmpty() async throws {
        vm.fetchRecords(for: "event_xyz")
        try await Task.sleep(nanoseconds: 50_000_000)
 
        XCTAssertTrue(vm.attendanceRecords.isEmpty, "Tidak boleh ada record untuk eventId yang salah")
    }
 
    func test_saveRecord_Success_AppendsToList() async throws {
        let newRecord = AttendanceRecord(
            eventId: "event_abc",
            scheduleId: nil,
            name: "Rapat Sesi 2",
            date: Date(),
            attendedMemberIds: [],
            targetMemberIds: ["user_123"],
            attendanceTimes: [:]
        )
 
        vm.saveRecord(newRecord)
        try await Task.sleep(nanoseconds: 50_000_000)
 
        XCTAssertEqual(mockAttendanceService.mockRecords.count, 2, "Record baru harus tersimpan di service")
        XCTAssertTrue(vm.errorMessage.isEmpty)
    }
 
    func test_saveRecord_Error_SetsErrorMessage() async throws {
        mockAttendanceService.shouldThrowError = true
 
        let newRecord = AttendanceRecord(
            eventId: "event_abc",
            scheduleId: nil,
            name: "Gagal Simpan",
            date: Date(),
            attendedMemberIds: [],
            targetMemberIds: [],
            attendanceTimes: [:]
        )
 
        vm.saveRecord(newRecord)
        try await Task.sleep(nanoseconds: 50_000_000)
 
        XCTAssertFalse(vm.errorMessage.isEmpty, "Error message harus terisi saat saveRecord gagal")
    }
 
    func test_deleteRecord_Success_RemovesFromList() async throws {
        vm.fetchRecords(for: "event_abc")
        try await Task.sleep(nanoseconds: 50_000_000)
 
        vm.deleteRecord(recordId: "rec_abc")
        try await Task.sleep(nanoseconds: 50_000_000)
 
        XCTAssertTrue(mockAttendanceService.mockRecords.isEmpty, "Record harus terhapus dari service")
        XCTAssertTrue(vm.errorMessage.isEmpty)
    }
 
    func test_deleteRecord_Error_SetsErrorMessage() async throws {
        mockAttendanceService.shouldThrowError = true
 
        vm.deleteRecord(recordId: "rec_abc")
        try await Task.sleep(nanoseconds: 50_000_000)
 
        XCTAssertFalse(vm.errorMessage.isEmpty, "Error message harus terisi saat deleteRecord gagal")
    }
 
    func test_updateAttendance_Success_UpdatesService() async throws {
        let newTime = Date()
        vm.updateAttendance(
            recordId: "rec_abc",
            attendedMemberIds: ["user_123", "user_456"],
            attendanceTimes: ["user_123": newTime, "user_456": newTime]
        )
        try await Task.sleep(nanoseconds: 50_000_000)
 
        let updated = mockAttendanceService.mockRecords.first { $0.id == "rec_abc" }
        XCTAssertEqual(updated?.attendedMemberIds.count, 2, "attendedMemberIds harus ter-update menjadi 2 anggota")
        XCTAssertTrue(vm.errorMessage.isEmpty)
    }
 
    func test_updateAttendance_Error_SetsErrorMessage() async throws {
        mockAttendanceService.shouldThrowError = true
 
        vm.updateAttendance(
            recordId: "rec_abc",
            attendedMemberIds: ["user_123"],
            attendanceTimes: [:]
        )
        try await Task.sleep(nanoseconds: 50_000_000)
 
        XCTAssertFalse(vm.errorMessage.isEmpty, "Error message harus terisi saat updateAttendance gagal")
    }
 
    func test_getRecords_FiltersCorrectlyByEventId() async throws {
        mockAttendanceService.mockRecords.append(
            AttendanceRecord(
                id: "rec_other",
                eventId: "event_xyz",
                scheduleId: nil,
                name: "Event Lain",
                date: Date(),
                attendedMemberIds: [],
                targetMemberIds: [],
                attendanceTimes: [:]
            )
        )
 
        vm.fetchRecords(for: "event_abc")
        try await Task.sleep(nanoseconds: 50_000_000)
 
        let filtered = vm.getRecords(for: "event_abc")
        XCTAssertEqual(filtered.count, 1, "getRecords harus hanya mengembalikan record milik event_abc")
        XCTAssertEqual(filtered.first?.id, "rec_abc")
    }
}
 

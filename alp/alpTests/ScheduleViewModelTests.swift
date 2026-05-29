//
//  ScheduleViewModelTests.swift
//  alpTests
//
//  Created by Vincent on 28/05/26.
//

import Foundation
import XCTest
@testable import alp

class MockScheduleService: ScheduleServiceProtocol {
    var mockSchedules: [Schedule] = []
    var shouldThrowError = false
    
    func fetchSchedules(forEventId eventId: String) async throws -> [Schedule] {
        if shouldThrowError { throw NSError(domain: "Test", code: 500) }
        return mockSchedules.filter { $0.eventId == eventId }
    }
    
    func addSchedule(_ schedule: Schedule) async throws -> String {
        if shouldThrowError { throw NSError(domain: "Test", code: 500) }
        var element = schedule
        let generatedId = UUID().uuidString
        element.id = generatedId
        mockSchedules.append(element)
        return generatedId
    }
    
    func updateSchedule(_ schedule: Schedule) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 500) }
        if let index = mockSchedules.firstIndex(where: { $0.id == schedule.id }) {
            mockSchedules[index] = schedule
        }
    }
    
    func deleteSchedule(id: String) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 500) }
        mockSchedules.removeAll(where: { $0.id == id })
    }
}

@MainActor
final class ScheduleViewModelTests: XCTestCase {
    
    var viewModel: ScheduleViewModel!
    var mockService: MockScheduleService!
    
    override func setUp() {
        super.setUp()
        mockService = MockScheduleService()
        viewModel = ScheduleViewModel(service: mockService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }
    
    func testAddAndFetchScheduleSuccess() async {
        let schedule = Schedule(eventId: "event_01", title: "Briefing Panitia", date: Date(), endDate: Date().addingTimeInterval(3600), location: "Ruang Rapat", creatorId: "user_admin", assignedTo: ["panitia_01", "panitia_02"])
        
        await viewModel.addSchedule(schedule)
        
        XCTAssertEqual(viewModel.schedules.count, 1)
        XCTAssertEqual(viewModel.schedules.first?.title, "Briefing Panitia")
    }
    
    func testEditScheduleSuccess() async {
        let initialSchedule = Schedule(id: "sch_123", eventId: "event_01", title: "Olah Data Awal", date: Date(), endDate: Date(), location: "Kosan", creatorId: "admin", assignedTo: ["panitia_01"])
        mockService.mockSchedules = [initialSchedule]
        await viewModel.loadSchedules(for: "event_01")
        
        var updatedSchedule = initialSchedule
        updatedSchedule.title = "Olah Data Final (Updated)"
        updatedSchedule.location = "Lab Komputer"
        
        await viewModel.editSchedule(updatedSchedule)
        
        XCTAssertEqual(viewModel.schedules.first?.title, "Olah Data Final (Updated)")
        XCTAssertEqual(viewModel.schedules.first?.location, "Lab Komputer")
    }
    
    func testRemoveScheduleSuccess() async {
        let initialSchedule = Schedule(id: "sch_123", eventId: "event_01", title: "Evaluasi", date: Date(), endDate: Date(), location: "Online", creatorId: "admin", assignedTo: ["panitia_01"])
        mockService.mockSchedules = [initialSchedule]
        await viewModel.loadSchedules(for: "event_01")
        
        await viewModel.removeSchedule(id: "sch_123")
        
        XCTAssertTrue(viewModel.schedules.isEmpty)
    }
    
    func testApplyFilterByDivision() async {
        let schedule1 = Schedule(id: "1", eventId: "ev_1", title: "Desain Banner", date: Date(), endDate: Date(), location: "Studio", creatorId: "adm", assignedTo: ["panitia_dkv_01", "panitia_dkv_02"])
        let schedule2 = Schedule(id: "2", eventId: "ev_1", title: "Setting Jaringan", date: Date(), endDate: Date(), location: "Aula", creatorId: "adm", assignedTo: ["panitia_it_01"])
        
        mockService.mockSchedules = [schedule1, schedule2]
        await viewModel.loadSchedules(for: "ev_1")
        
        viewModel.selectedDivisionMemberIds = ["panitia_dkv_01", "panitia_dkv_02"]
        XCTAssertEqual(viewModel.filteredSchedules.count, 1)
        XCTAssertEqual(viewModel.filteredSchedules.first?.title, "Desain Banner")
        
        viewModel.selectedDivisionMemberIds = nil
        XCTAssertEqual(viewModel.filteredSchedules.count, 2)
    }
}

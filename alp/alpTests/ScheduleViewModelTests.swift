//
//  ScheduleViewModelTests.swift
//  alpTests
//
//  Created by Vincent on 28/05/26.
//
//
//  ScheduleViewModelTests.swift
//  alpTests
//

import Foundation
import XCTest
@testable import alp

private final class MockScheduleService: ScheduleServiceProtocol {
    var schedules: [Schedule] = []
    var shouldThrowError = false
    var addedSchedules: [Schedule] = []
    var updatedSchedules: [Schedule] = []
    var deletedScheduleIds: [String] = []
    var nextGeneratedId = "schedule-new"

    func fetchSchedules(forEventId eventId: String) async throws -> [Schedule] {
        if shouldThrowError { throw testError }
        return schedules.filter { $0.eventId == eventId }
    }

    func addSchedule(_ schedule: Schedule) async throws -> String {
        if shouldThrowError { throw testError }
        addedSchedules.append(schedule)
        var savedSchedule = schedule
        savedSchedule.id = nextGeneratedId
        schedules.append(savedSchedule)
        return nextGeneratedId
    }

    func updateSchedule(_ schedule: Schedule) async throws {
        if shouldThrowError { throw testError }
        updatedSchedules.append(schedule)
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
        }
    }

    func deleteSchedule(id: String) async throws {
        if shouldThrowError { throw testError }
        deletedScheduleIds.append(id)
        schedules.removeAll { $0.id == id }
    }

    private var testError: NSError {
        NSError(domain: "ScheduleServiceTests", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock failure"])
    }
}

@MainActor
final class ScheduleViewModelTests: XCTestCase {
    private var viewModel: ScheduleViewModel!
    private var service: MockScheduleService!

    override func setUp() {
        super.setUp()
        service = MockScheduleService()
        viewModel = ScheduleViewModel(service: service)
    }

    override func tearDown() {
        viewModel = nil
        service = nil
        super.tearDown()
    }

    func testLoadSchedulesFetchesOnlyRequestedEventAndAppliesDefaultFilter() async {
        service.schedules = [
            makeSchedule(id: "schedule-1", eventId: "event-a", title: "Briefing"),
            makeSchedule(id: "schedule-2", eventId: "event-b", title: "Different Event")
        ]

        await viewModel.loadSchedules(for: "event-a")

        XCTAssertEqual(viewModel.schedules.compactMap(\.id), ["schedule-1"])
        XCTAssertEqual(viewModel.filteredSchedules.compactMap(\.id), ["schedule-1"])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadSchedulesFailureSetsErrorAndStopsLoading() async {
        service.shouldThrowError = true

        await viewModel.loadSchedules(for: "event-a")

        XCTAssertTrue(viewModel.schedules.isEmpty)
        XCTAssertTrue(viewModel.filteredSchedules.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Gagal memuat jadwal: Mock failure")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testAddScheduleStoresGeneratedIdAndRefreshesFilteredSchedules() async {
        let schedule = makeSchedule(id: nil, eventId: "event-a", title: "Rapat Logistik", assignedTo: ["member-1"])

        await viewModel.addSchedule(schedule)

        XCTAssertEqual(service.addedSchedules.count, 1)
        XCTAssertEqual(viewModel.schedules.first?.id, "schedule-new")
        XCTAssertEqual(viewModel.filteredSchedules.first?.title, "Rapat Logistik")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testAddScheduleFailureDoesNotMutateSchedules() async {
        service.shouldThrowError = true
        let schedule = makeSchedule(id: nil, eventId: "event-a", title: "Gagal Simpan")

        await viewModel.addSchedule(schedule)

        XCTAssertTrue(viewModel.schedules.isEmpty)
        XCTAssertTrue(service.addedSchedules.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Gagal menambahkan jadwal: Mock failure")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testEditScheduleUpdatesExistingScheduleAndFilterResult() async {
        service.schedules = [
            makeSchedule(id: "schedule-1", eventId: "event-a", title: "Rundown Awal", assignedTo: ["member-1"])
        ]
        await viewModel.loadSchedules(for: "event-a")

        var updatedSchedule = service.schedules[0]
        updatedSchedule.title = "Rundown Final"
        updatedSchedule.location = "Aula Utama"

        await viewModel.editSchedule(updatedSchedule)

        XCTAssertEqual(service.updatedSchedules.compactMap(\.id), ["schedule-1"])
        XCTAssertEqual(viewModel.schedules.first?.title, "Rundown Final")
        XCTAssertEqual(viewModel.filteredSchedules.first?.location, "Aula Utama")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testRemoveScheduleDeletesExistingScheduleAndRefreshesFilter() async {
        service.schedules = [
            makeSchedule(id: "schedule-1", eventId: "event-a", title: "Evaluasi"),
            makeSchedule(id: "schedule-2", eventId: "event-a", title: "Closing")
        ]
        await viewModel.loadSchedules(for: "event-a")

        await viewModel.removeSchedule(id: "schedule-1")

        XCTAssertEqual(service.deletedScheduleIds, ["schedule-1"])
        XCTAssertEqual(viewModel.schedules.compactMap(\.id), ["schedule-2"])
        XCTAssertEqual(viewModel.filteredSchedules.compactMap(\.id), ["schedule-2"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSelectedDivisionMemberIdsFiltersSchedulesByAssignedMembers() async {
        service.schedules = [
            makeSchedule(id: "schedule-design", eventId: "event-a", title: "Desain Banner", assignedTo: ["member-design", "member-copy"]),
            makeSchedule(id: "schedule-tech", eventId: "event-a", title: "Setup Jaringan", assignedTo: ["member-tech"])
        ]
        await viewModel.loadSchedules(for: "event-a")

        viewModel.selectedDivisionMemberIds = ["member-design"]

        XCTAssertEqual(viewModel.filteredSchedules.map(\.title), ["Desain Banner"])
    }

    func testClearingSelectedDivisionShowsAllSchedulesAgain() async {
        service.schedules = [
            makeSchedule(id: "schedule-design", eventId: "event-a", assignedTo: ["member-design"]),
            makeSchedule(id: "schedule-tech", eventId: "event-a", assignedTo: ["member-tech"])
        ]
        await viewModel.loadSchedules(for: "event-a")
        viewModel.selectedDivisionMemberIds = ["member-tech"]

        viewModel.selectedDivisionMemberIds = nil

        XCTAssertEqual(viewModel.filteredSchedules.compactMap(\.id), ["schedule-design", "schedule-tech"])
    }

    private func makeSchedule(
        id: String? = "schedule-1",
        eventId: String = "event-a",
        title: String = "Schedule",
        assignedTo: [String] = ["member-1"]
    ) -> Schedule {
        Schedule(
            id: id,
            eventId: eventId,
            title: title,
            date: Date(timeIntervalSince1970: 1_000),
            endDate: Date(timeIntervalSince1970: 2_000),
            location: "Ruang 101",
            creatorId: "owner-1",
            assignedTo: assignedTo
        )
    }
}

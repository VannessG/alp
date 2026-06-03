//
//  AttendanceViewModel.swift
//  alp
//
//  Created by Lemuel on 02/06/26.
//

import Foundation
import Combine

@MainActor
class AttendanceViewModel: ObservableObject {

    @Published var attendanceRecords: [AttendanceRecord] = []
    @Published var errorMessage = ""

    private let attendanceService: AttendanceServiceProtocol
    private var cancelListener: (() -> Void)?

    init(attendanceService: AttendanceServiceProtocol = AttendanceService.shared) {
        self.attendanceService = attendanceService
    }

    func fetchRecords(for eventId: String) {
        cancelListener?()

        cancelListener = attendanceService.observeAttendanceRecords(for: eventId) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let records):
                    self.attendanceRecords = records
                    self.errorMessage = ""

                case .failure(let error):
                    self.attendanceRecords = []
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func saveRecord(_ record: AttendanceRecord) {
        Task {
            do {
                try await attendanceService.saveRecord(record)
                self.errorMessage = ""
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func deleteRecord(recordId: String) {
        Task {
            do {
                try await attendanceService.deleteRecord(recordId: recordId)
                self.errorMessage = ""
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func updateAttendance(
        recordId: String,
        attendedMemberIds: [String],
        attendanceTimes: [String: Date]
    ) {
        Task {
            do {
                try await attendanceService.updateAttendance(
                    recordId: recordId,
                    attendedMemberIds: attendedMemberIds,
                    attendanceTimes: attendanceTimes
                )
                self.errorMessage = ""
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func getRecords(for eventId: String) -> [AttendanceRecord] {
        attendanceRecords.filter { $0.eventId == eventId }
    }

    deinit {
        cancelListener?()
    }
}

//
//  ScheduleViewModel.swift
//  alp
//
//  Created by Vincent on 28/05/26.
//

import Foundation
import Combine

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var schedules: [Schedule] = []
    @Published var filteredSchedules: [Schedule] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Menyimpan daftar ID Anggota dari divisi yang sedang dipilih untuk filter.
    // Jika nil, berarti menampilkan "Semua Panitia".
    @Published var selectedDivisionMemberIds: [String]? = nil {
        didSet {
            applyFilter()
        }
    }
    
    private let service: ScheduleServiceProtocol
    private var currentEventId: String = ""
    
    init(service: ScheduleServiceProtocol = FirestoreScheduleService()) {
        self.service = service
    }
    
    func loadSchedules(for eventId: String) async {
        self.currentEventId = eventId
        isLoading = true
        errorMessage = nil
        do {
            schedules = try await service.fetchSchedules(forEventId: eventId)
            applyFilter()
        } catch {
            errorMessage = "Gagal memuat jadwal: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func addSchedule(_ schedule: Schedule) async {
        isLoading = true
        errorMessage = nil
        do {
            var newSchedule = schedule
            let newId = try await service.addSchedule(schedule)
            newSchedule.id = newId
            schedules.append(newSchedule)
            applyFilter()
        } catch {
            errorMessage = "Gagal menambahkan jadwal: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func editSchedule(_ schedule: Schedule) async {
        isLoading = true
        errorMessage = nil
        do {
            try await service.updateSchedule(schedule)
            if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
                schedules[index] = schedule
                applyFilter()
            }
        } catch {
            errorMessage = "Gagal memperbarui jadwal: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func removeSchedule(id: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await service.deleteSchedule(id: id)
            schedules.removeAll(where: { $0.id == id })
            applyFilter()
        } catch {
            errorMessage = "Gagal menghapus jadwal: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // Logika Filter
    private func applyFilter() {
        guard let filterIds = selectedDivisionMemberIds else {
            filteredSchedules = schedules
            return
        }
        
        filteredSchedules = schedules.filter { schedule in
            let assignedSet = Set(schedule.assignedTo)
            let filterSet = Set(filterIds)
            return !assignedSet.isDisjoint(with: filterSet)
        }
    }
}

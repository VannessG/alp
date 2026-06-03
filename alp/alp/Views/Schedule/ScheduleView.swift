//
//  ScheduleView.swift
//  alp
//
//  Created by Vincent on 03/06/26.
//
import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var divisionVM: DivisionViewModel
    @StateObject var scheduleVM = ScheduleViewModel()
    
    @State private var isShowingForm = false
    @State private var selectedSchedule: Schedule? = nil
    @State private var selectedDivisionId: String = "All"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    filterPicker
                    
                    if scheduleVM.isLoading && scheduleVM.schedules.isEmpty {
                        ProgressView("Memuat Jadwal...")
                            .frame(maxHeight: .infinity)
                    } else if scheduleVM.filteredSchedules.isEmpty {
                        emptyState
                    } else {
                        List {
                            let grouped = Dictionary(grouping: scheduleVM.filteredSchedules) { schedule in
                                Calendar.current.startOfDay(for: schedule.date)
                            }
                            let sortedDates = grouped.keys.sorted()
                            
                            ForEach(sortedDates, id: \.self) { date in
                                Section(header: Text(formatHeaderDate(date)).font(.subheadline).bold()) {
                                    ForEach(grouped[date] ?? [], id: \.title) { schedule in
                                        ScheduleRow(schedule: schedule)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                selectedSchedule = schedule
                                                isShowingForm = true
                                            }
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) {
                                                    Task { await scheduleVM.removeSchedule(id: schedule.id ?? "") }
                                                } label: {
                                                    Label("Hapus", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Jadwal Acara")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedSchedule = nil
                        isShowingForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $isShowingForm) {
                ScheduleFormView(
                    scheduleVM: scheduleVM,
                    activeEventId: eventVM.activeEvent?.id ?? "",
                    creatorId: authVM.currentUser?.id ?? "",
                    editingSchedule: selectedSchedule
                )
            }
            .onAppear {
                if let eventId = eventVM.activeEvent?.id {
                    Task {
                        await scheduleVM.loadSchedules(for: eventId)
                        divisionVM.fetchDivisions(for: eventId)
                    }
                }
            }
            .alert("Error", isPresented: Binding(get: { scheduleVM.errorMessage != nil }, set: { _ in scheduleVM.errorMessage = nil })) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(scheduleVM.errorMessage ?? "")
            }
        }
    }
    
    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterButton(title: "Semua", isSelected: selectedDivisionId == "All") {
                    selectedDivisionId = "All"
                    scheduleVM.selectedDivisionMemberIds = nil
                }
                
                ForEach(divisionVM.divisions) { div in
                    FilterButton(title: div.name, isSelected: selectedDivisionId == div.id) {
                        selectedDivisionId = div.id ?? ""
                        let memberIds = divisionVM.members
                            .filter { $0.division == div.name }
                            .map { $0.userId }
                            
                        scheduleVM.selectedDivisionMemberIds = memberIds
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
    
    private var emptyState: some View {
        VStack(spacing: 15) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Tidak ada jadwal")
                .font(.headline)
            Text("Ketuk tombol + untuk menambahkan agenda baru.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func formatHeaderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct ScheduleFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var scheduleVM: ScheduleViewModel
    
    let activeEventId: String
    let creatorId: String
    var editingSchedule: Schedule?
    
    @State private var title = ""
    @State private var location = ""
    @State private var date = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isPresenceRequired = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informasi Dasar") {
                    TextField("Judul Agenda", text: $title)
                    TextField("Lokasi", text: $location)
                }
                
                Section("Waktu") {
                    DatePicker("Mulai", selection: $date)
                    DatePicker("Selesai", selection: $endDate, in: date...)
                }
                
                Section("Opsi") {
                    Toggle("Wajib Absen", isOn: $isPresenceRequired)
                }
            }
            .navigationTitle(editingSchedule == nil ? "Jadwal Baru" : "Edit Jadwal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        saveAction()
                    }
                    .disabled(title.isEmpty || location.isEmpty)
                }
            }
            .onAppear {
                if let schedule = editingSchedule {
                    title = schedule.title
                    location = schedule.location
                    date = schedule.date
                    endDate = schedule.endDate
                    isPresenceRequired = schedule.isPresenceRequired
                }
            }
        }
    }
    
    private func saveAction() {
        Task {
            let schedule = Schedule(
                id: editingSchedule?.id,
                eventId: activeEventId,
                title: title,
                date: date,
                endDate: endDate,
                location: location,
                creatorId: creatorId,
                assignedTo: editingSchedule?.assignedTo ?? [],
                isPresenceRequired: isPresenceRequired,
                attendedMemberIds: editingSchedule?.attendedMemberIds ?? [],
                absentMemberIds: editingSchedule?.absentMemberIds ?? [],
                isAttendanceSaved: editingSchedule?.isAttendanceSaved ?? false
            )
            
            if editingSchedule == nil {
                await scheduleVM.addSchedule(schedule)
            } else {
                await scheduleVM.editSchedule(schedule)
            }
            dismiss()
        }
    }
}

struct ScheduleRow: View {
    let schedule: Schedule
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text(schedule.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 10) {
                    Label(formatTimeRange(start: schedule.date, end: schedule.endDate), systemImage: "clock")
                    Label(schedule.location, systemImage: "mappin.and.ellipse")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if schedule.isPresenceRequired {
                    Image(systemName: "person.badge.shield.check.fill")
                        .foregroundColor(.orange)
                        .help("Wajib Absen")
                }
                
                if schedule.isAttendanceSaved {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

#Preview {
    ScheduleView()
}

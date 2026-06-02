//
//  ManualAttendanceCheckView.swift
//  alp
//
//  Created by Lemuel on 02/06/26.
//

import SwiftUI

struct ManualAttendanceCheckView: View {
    @EnvironmentObject var attendanceVM: AttendanceViewModel
    @EnvironmentObject var memberVM: EventMemberViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass

    let name: String
    let date: Date
    let onSave: () -> Void

    @State private var attendedMemberIds: [String] = []
    @State private var attendanceTimes: [String: Date] = [:]
    @State private var searchText = ""
    @State private var pendingUserId: String? = nil
    @State private var showConfirmAlert = false

    private var activeEvent: Event? { eventVM.activeEvent }

    private var allMembers: [EventMember] {
        memberVM.getEventMembers(activeEvent: activeEvent)
    }

    private var filteredMembers: [EventMember] {
        guard !searchText.isEmpty else { return allMembers }
        return allMembers.filter { m in
            guard let user = memberVM.getUser(byId: m.userId) else { return false }
            return user.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                searchBarHeader

                List {
                    infoSection
                    memberListSection
                }
                .listStyle(.insetGrouped)

                saveButton
            }
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Konfirmasi", isPresented: $showConfirmAlert) {
            Button("Hadir") {
                if let uid = pendingUserId {
                    if !attendedMemberIds.contains(uid) {
                        attendedMemberIds.append(uid)
                        attendanceTimes[uid] = Date()
                    }
                }
                pendingUserId = nil
            }
            Button("Batal", role: .cancel) {
                pendingUserId = nil
            }
        } message: {
            Text("Apakah anggota ini hadir?")
        }
        .preferredColorScheme(.light)
    }

    private var searchBarHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(UIColor.tertiaryLabel))
            TextField("Cari anggota...", text: $searchText)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(UIColor.separator).opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var infoSection: some View {
        Section(header: Text("Informasi Presensi")) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(date, style: .date)
                    Text("•")
                    Image(systemName: "clock")
                    Text(date, style: .time)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)

            HStack {
                Label("Hadir", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(attendedMemberIds.count) / \(allMembers.count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }

    private var memberListSection: some View {
        Section(header: Text("Daftar Anggota")) {
            if filteredMembers.isEmpty {
                Text("Tidak ada anggota ditemukan.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(filteredMembers) { member in
                    if let user = memberVM.getUser(byId: member.userId) {
                        let uid = user.id ?? ""
                        let isAttended = attendedMemberIds.contains(uid)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name)
                                    .font(.system(size: 15, weight: .medium))
                                Text(member.division)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Image(systemName: isAttended ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isAttended ? .green : .gray)
                                    .font(.title3)

                                if isAttended, let time = attendanceTimes[uid] {
                                    Text(time.formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isAttended {
                                attendedMemberIds.removeAll { $0 == uid }
                                attendanceTimes.removeValue(forKey: uid)
                            } else {
                                pendingUserId = uid
                                showConfirmAlert = true
                            }
                        }
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: savePresence) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                Text("Close & Save Presence")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.red.opacity(0.3), radius: 5, y: 3)
        }
        .padding(16)
    }

    private func savePresence() {
        guard let eventId = activeEvent?.id else { return }

        let targetIds = allMembers.compactMap { $0.userId as String? }

        let record = AttendanceRecord(
            eventId: eventId,
            scheduleId: nil,
            name: name,
            date: date,
            attendedMemberIds: attendedMemberIds,
            targetMemberIds: targetIds,
            attendanceTimes: attendanceTimes
        )

        attendanceVM.saveRecord(record)
        onSave()
    }
}

//
//  PresenceHistoryView.swift
//  alp
//
//  Created by Lemuel on 02/06/26.
//

import SwiftUI

struct PresenceHistoryView: View {
    @EnvironmentObject var attendanceVM: AttendanceViewModel
    @EnvironmentObject var memberVM: EventMemberViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    private let indigo = Color(red: 0.29, green: 0.34, blue: 0.90)
    private let purple = Color(red: 0.58, green: 0.28, blue: 0.90)

    private var records: [AttendanceRecord] {
        guard let eventId = eventVM.activeEvent?.id else { return [] }
        return attendanceVM.getRecords(for: eventId)
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            if attendanceVM.isLoading {
                loadingState
            } else if !attendanceVM.errorMessage.isEmpty {
                errorState
            } else if records.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(records) { record in
                            NavigationLink(destination:
                                PresenceHistoryDetailView(record: record)
                                    .environmentObject(memberVM)
                            ) {
                                historyRow(record: record)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: 650)
                    .scaleEffect(sizeClass == .regular ? 1.55 : 1.0, anchor: .top)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, sizeClass == .regular ? 450 : 0)
                }
            }
        }
        .navigationTitle("Presence History")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .onAppear {
            if let eventId = eventVM.activeEvent?.id {
                attendanceVM.fetchRecords(for: eventId)
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Memuat histori...")
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
    }

    private var errorState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 70, height: 70)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.red)
            }
            VStack(spacing: 4) {
                Text("Gagal memuat histori")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                Text(attendanceVM.errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
            Button(action: {
                attendanceVM.resetFetchState()
                if let eventId = eventVM.activeEvent?.id {
                    attendanceVM.fetchRecords(for: eventId)
                }
            }) {
                Text("Coba Lagi")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.horizontal, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(indigo.opacity(0.1))
                    .frame(width: 70, height: 70)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(indigo)
            }
            VStack(spacing: 4) {
                Text("Belum ada histori")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                Text("Histori presensi yang disimpan akan tampil di sini.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }

    private func historyRow(record: AttendanceRecord) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(indigo.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: record.scheduleId == nil ? "pencil.and.list.clipboard" : "calendar.badge.checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(indigo)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(UIColor.label))

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(record.date, style: .date)
                    Text("•")
                    Image(systemName: "clock")
                    Text(record.date, style: .time)
                }
                .font(.system(size: 12))
                .foregroundColor(Color(UIColor.secondaryLabel))

                Text("Hadir: \(record.attendedMemberIds.count) / \(record.targetMemberIds.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(indigo)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(UIColor.separator).opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct PresenceHistoryDetailView: View {
    @EnvironmentObject var memberVM: EventMemberViewModel
    let record: AttendanceRecord

    private let indigo = Color(red: 0.29, green: 0.34, blue: 0.90)
    private let purple = Color(red: 0.58, green: 0.28, blue: 0.90)

    private var presentMembers: [String] {
        record.targetMemberIds.filter { record.attendedMemberIds.contains($0) }
    }

    private var absentMembers: [String] {
        record.targetMemberIds.filter { !record.attendedMemberIds.contains($0) }
    }

    var body: some View {
        List {
            summarySection
            presentSection
            absentSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Detail Presensi")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
    }

    private var summarySection: some View {
        Section(header: Text("Detail Kehadiran")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(record.name)
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(record.date.formatted())
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                HStack {
                    Label("Hadir: \(presentMembers.count)", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Spacer()
                    Label("Tidak Hadir: \(absentMembers.count)", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .font(.system(size: 14, weight: .semibold))
                .padding(.top, 4)
            }
            .padding(.vertical, 4)

            let rate = record.targetMemberIds.isEmpty ? 0.0 : Double(record.attendedMemberIds.count) / Double(record.targetMemberIds.count)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Tingkat Kehadiran")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(rate * 100))%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(indigo)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [indigo, purple], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * rate, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(.vertical, 4)
        }
    }

    private var presentSection: some View {
        Section(header: Text("Anggota Hadir (\(presentMembers.count))")) {
            if presentMembers.isEmpty {
                Text("Tidak ada yang hadir")
                    .foregroundColor(.secondary)
            } else {
                ForEach(presentMembers, id: \.self) { uid in
                    if let user = memberVM.getUser(byId: uid) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Text(String(user.name.prefix(1)).uppercased())
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            Text(user.name)
                                .font(.system(size: 15))
                            Spacer()
                            if let time = record.attendanceTimes[uid] {
                                Text(time.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var absentSection: some View {
        Section(header: Text("Anggota Tidak Hadir (\(absentMembers.count))")) {
            if absentMembers.isEmpty {
                Text("Semua anggota hadir")
                    .foregroundColor(.secondary)
            } else {
                ForEach(absentMembers, id: \.self) { uid in
                    if let user = memberVM.getUser(byId: uid) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Text(String(user.name.prefix(1)).uppercased())
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            Text(user.name)
                                .font(.system(size: 15))
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

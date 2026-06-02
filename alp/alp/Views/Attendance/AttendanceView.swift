//
//  AttendanceView.swift
//  alp
//
//  Created by Lemuel on 02/06/26.
//

import SwiftUI

private enum DSAtt {
    static let indigo      = Color(red: 0.29, green: 0.34, blue: 0.90)
    static let purple      = Color(red: 0.58, green: 0.28, blue: 0.90)
    static let indigoMuted = Color(red: 0.29, green: 0.34, blue: 0.90).opacity(0.12)
    static let bgPrimary   = Color(UIColor.systemGroupedBackground)
    static let bgSurface   = Color(UIColor.secondarySystemGroupedBackground)
    static let bgTertiary  = Color(UIColor.tertiarySystemGroupedBackground)
    static let textPrimary   = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary  = Color(UIColor.tertiaryLabel)
    static let border = Color(UIColor.separator).opacity(0.4)
    static let brandGradient = LinearGradient(
        colors: [indigo, purple],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct AttendanceView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var memberVM: EventMemberViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var attendanceVM: AttendanceViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    @State private var searchText = ""
    @State private var showCreateManual = false
    @State private var manualName = ""
    @State private var manualDate = Date()
    @State private var showManualCheck = false

    private var activeEvent: Event? { eventVM.activeEvent }
    private var currentRole: Role { memberVM.currentUserRole }

    private var filteredMembers: [EventMember] {
        let all = memberVM.getEventMembers(activeEvent: activeEvent)
        guard !searchText.isEmpty else { return all }
        return all.filter { m in
            guard let user = memberVM.getUser(byId: m.userId) else { return false }
            return user.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DSAtt.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if currentRole == .owner || currentRole == .coordinator {
                            createManualButton
                        }

                        membersSection
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 650)
                    .scaleEffect(sizeClass == .regular ? 1.55 : 1.0, anchor: .top)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, sizeClass == .regular ? 450 : 0)
                }
            }
            .navigationTitle("Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination:
                        PresenceHistoryView()
                            .environmentObject(attendanceVM)
                            .environmentObject(memberVM)
                            .environmentObject(eventVM)
                    ) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(DSAtt.indigo)
                    }
                }
            }
            .sheet(isPresented: $showCreateManual) {
                manualCreationSheet
            }
            .onAppear {
                if let eventId = activeEvent?.id {
                    attendanceVM.fetchRecords(for: eventId)
                    memberVM.fetchMembers(for: eventId, currentUserId: authVM.currentUser?.id)
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private var createManualButton: some View {
        Button(action: { showCreateManual = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Create Manual Presence")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DSAtt.brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: DSAtt.indigo.opacity(0.3), radius: 6, y: 3)
        }
        .padding(.horizontal, 16)
    }

    private var membersSection: some View {
        VStack(spacing: 12) {
            attSectionHeader(title: "Members")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DSAtt.textTertiary)
                TextField("Cari anggota...", text: $searchText)
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(DSAtt.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DSAtt.border, lineWidth: 1)
            )
            .padding(.horizontal, 16)

            if filteredMembers.isEmpty {
                Text("Anggota tidak ditemukan.")
                    .font(.system(size: 14))
                    .foregroundColor(DSAtt.textSecondary)
                    .padding(.top, 10)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredMembers) { member in
                        if let user = memberVM.getUser(byId: member.userId) {
                            AttMemberRow(user: user, member: member)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }

    private var manualCreationSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detail Kehadiran")) {
                    TextField("Presence Name", text: $manualName)
                    DatePicker("Date & Start Time", selection: $manualDate)
                }
            }
            .navigationTitle("New Manual Presence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showCreateManual = false
                        manualName = ""
                        manualDate = Date()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination:
                        ManualAttendanceCheckView(
                            name: manualName,
                            date: manualDate,
                            onSave: {
                                showCreateManual = false
                                manualName = ""
                                manualDate = Date()
                            }
                        )
                        .environmentObject(attendanceVM)
                        .environmentObject(memberVM)
                        .environmentObject(eventVM)
                    ) {
                        Text("Next").bold()
                    }
                    .disabled(manualName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func attSectionHeader(title: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(DSAtt.brandGradient)
                .frame(width: 3, height: 16)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DSAtt.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
        }
    }
}

struct AttMemberRow: View {
    let user: User
    let member: EventMember

    private let indigo = Color(red: 0.29, green: 0.34, blue: 0.90)
    private let purple = Color(red: 0.58, green: 0.28, blue: 0.90)
    private var indigoMuted: Color { indigo.opacity(0.12) }
    private var gradient: LinearGradient {
        LinearGradient(colors: [indigo, purple], startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(indigoMuted)
                    .frame(width: 40, height: 40)
                Text(String(user.name.prefix(1)).uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(gradient)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                Text(member.division)
                    .font(.system(size: 12))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            Spacer()
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(UIColor.separator).opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.29, green: 0.34, blue: 0.90).opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

//
//  ManageMembersView.swift
//  alp
//
//  Created by Lemuel on 02/06/26.
//

import SwiftUI

struct ManageMembersView: View {
    @EnvironmentObject var memberVM: EventMemberViewModel
    @EnvironmentObject var divisionVM: DivisionViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    private var activeEvent: Event? { eventVM.activeEvent }
    private var isReadOnly: Bool { activeEvent?.status == "ended" }

    private var sortedMembers: [EventMember] {
        memberVM.getEventMembers(activeEvent: activeEvent).sorted { m1, m2 in
            if m1.role == .owner { return true }
            if m2.role == .owner { return false }
            if m1.role == .coordinator && m2.role == .member { return true }
            if m1.role == .member && m2.role == .coordinator { return false }
            return m1.division < m2.division
        }
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    memberListCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: 650)
                .scaleEffect(sizeClass == .regular ? 1.55 : 1.0, anchor: .top)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, sizeClass == .regular ? 450 : 0)
            }
        }
        .navigationTitle("Daftar Anggota")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let eventId = activeEvent?.id {
                memberVM.fetchMembers(for: eventId, currentUserId: authVM.currentUser?.id)
                divisionVM.fetchDivisions(for: eventId)
            }
        }
    }

    private var memberListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Anggota Event", icon: "person.3.fill", color: .blue)

            if sortedMembers.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.5))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Belum ada anggota")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Bagikan kode join agar anggota bisa bergabung.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(sortedMembers) { member in
                        if let user = memberVM.getUser(byId: member.userId) {
                            NavigationLink {
                                MemberDetailView(member: member, user: user)
                                    .environmentObject(memberVM)
                                    .environmentObject(divisionVM)
                                    .environmentObject(eventVM)
                                    .environmentObject(authVM)
                            } label: {
                                memberRow(member: member, user: user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if !memberVM.errorMessage.isEmpty {
                Text(memberVM.errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    private func memberRow(member: EventMember, user: User) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(roleColor(member.role).opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(String(user.name.prefix(1)).uppercased())
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(roleColor(member.role))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(user.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text(roleLabel(member.role).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(roleColor(member.role))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(roleColor(member.role).opacity(0.12))
                        .clipShape(Capsule())

                    if member.division != "Unassigned" && member.division != "General" {
                        Text(member.division)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3, height: 16)
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }

    private func roleLabel(_ role: Role) -> String {
        switch role {
        case .owner: return "Owner"
        case .coordinator: return "Coordinator"
        case .member: return "Member"
        }
    }

    private func roleColor(_ role: Role) -> Color {
        switch role {
        case .owner: return Color(red: 0.58, green: 0.28, blue: 0.90)
        case .coordinator: return Color(red: 0.97, green: 0.56, blue: 0.18)
        case .member: return .blue
        }
    }
}

#Preview {
    let mockAuth = AuthViewModel()
    mockAuth.currentUser = User(id: "u1", name: "Vanness", email: "vanness@test.com")

    let mockEvent = EventViewModel()
    mockEvent.activeEvent = Event(
        id: "event_1", name: "Kepanitiaan SIFT", joinCode: "SIFT26",
        announcement: "", ownerId: "u1", status: "active", members: ["u1", "u2", "u3"]
    )

    let mockMember = EventMemberViewModel()
    mockMember.members = [
        EventMember(id: "m1", eventId: "event_1", userId: "u1", role: .owner, division: "General"),
        EventMember(id: "m2", eventId: "event_1", userId: "u2", role: .coordinator, division: "Konsumsi"),
        EventMember(id: "m3", eventId: "event_1", userId: "u3", role: .member, division: "Konsumsi")
    ]
    mockMember.registeredUsers = [
        User(id: "u1", name: "Vanness", email: "vanness@test.com"),
        User(id: "u2", name: "Lemuel", email: "lemuel@test.com"),
        User(id: "u3", name: "Vincent", email: "vincent@test.com")
    ]

    let mockDivision = DivisionViewModel()
    mockDivision.divisions = [
        Division(id: "d1", eventId: "event_1", name: "Konsumsi"),
        Division(id: "d2", eventId: "event_1", name: "Dekorasi")
    ]

    return NavigationStack {
        ManageMembersView()
            .environmentObject(mockMember)
            .environmentObject(mockDivision)
            .environmentObject(mockEvent)
            .environmentObject(mockAuth)
    }
}

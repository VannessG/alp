//
//  MemberDetailView.swift
//  alp
//
//  Created by Lemuel on 02/06/26.
//

import SwiftUI

struct MemberDetailView: View {
    @EnvironmentObject var memberVM: EventMemberViewModel
    @EnvironmentObject var divisionVM: DivisionViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    var member: EventMember
    var user: User

    @State private var showEditSheet = false

    private var activeEvent: Event? { eventVM.activeEvent }
    private var isReadOnly: Bool { activeEvent?.status == "ended" }

    private var currentMember: EventMember {
        memberVM.members.first { $0.id == member.id } ?? member
    }

    private var canEdit: Bool {
        guard !isReadOnly else { return false }
        guard memberVM.currentUserRole == .owner else { return false }
        return currentMember.userId != authVM.currentUser?.id
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    profileCard
                    infoCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: 650)
                .scaleEffect(sizeClass == .regular ? 1.55 : 1.0, anchor: .top)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, sizeClass == .regular ? 450 : 0)
            }
        }
        .navigationTitle("Detail Anggota")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") { showEditSheet = true }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditMemberRoleView(member: currentMember)
                .environmentObject(memberVM)
                .environmentObject(divisionVM)
                .environmentObject(eventVM)
                .environmentObject(authVM)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 72, height: 72)
                        Text(String(user.name.prefix(1)).uppercased())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 6) {
                        Text(user.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(user.email)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))

                        Text(roleLabel(currentMember.role).uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .padding(.top, 2)
                    }
                }
                .padding(.vertical, 28)
            }
            .frame(height: 220)
            .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Member Info", icon: "person.text.rectangle.fill", color: .blue)

            VStack(spacing: 8) {
                infoRow(icon: "crown.fill", label: "Role", value: roleLabel(currentMember.role), color: roleColor(currentMember.role))
                Divider().padding(.leading, 44)
                infoRow(icon: "rectangle.stack.fill", label: "Divisi", value: currentMember.division, color: .blue)
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

    private func infoRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
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

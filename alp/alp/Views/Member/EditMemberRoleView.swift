//
//  EditMemberRoleView.swift
//  alp
//
//  Created by Lemuel on 02/06/26.
//

import SwiftUI

struct EditMemberRoleView: View {
    @EnvironmentObject var memberVM: EventMemberViewModel
    @EnvironmentObject var divisionVM: DivisionViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var member: EventMember

    @State private var selectedRole: Role = .member
    @State private var divisionName: String = "Unassigned"

    private var activeEvent: Event? { eventVM.activeEvent }

    private var divisions: [Division] {
        divisionVM.getActiveEventDivisions(activeEvent: activeEvent)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if let user = memberVM.getUser(byId: member.userId) {
                            userCard(user: user)
                        }

                        rolePickerCard
                        
                        if selectedRole != .owner {
                            divisionPickerCard
                        } else {
                            ownerInfoCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Edit Anggota")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedRole = member.role
                divisionName = member.division
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        if let id = member.id {
                            let finalDivision = selectedRole == .owner ? "General" : divisionName
                            let currentUserId = authVM.currentUser?.id
                            let eventId = activeEvent?.id ?? ""
                            memberVM.updateMember(
                                    memberId: id,
                                    newRole: selectedRole,
                                    newDivision: finalDivision,
                                    currentUserId: currentUserId,
                                    eventId: eventId
                            )
                        }
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.blue)
                }
            }
        }
    }

    private func userCard(user: User) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 50, height: 50)
                Text(String(user.name.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.blue)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Text(user.email)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
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

    private var rolePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Ubah Role", icon: "person.badge.key.fill", color: .blue)

            VStack(spacing: 4) {
                roleOption(.member, label: "Member", icon: "person.fill",
                           color: .blue)
                Divider().padding(.leading, 44)
                roleOption(.coordinator, label: "Coordinator", icon: "person.badge.key.fill",
                           color: Color(red: 0.97, green: 0.56, blue: 0.18))
                Divider().padding(.leading, 44)
                roleOption(.owner, label: "Owner", icon: "crown.fill",
                           color: Color(red: 0.58, green: 0.28, blue: 0.90))
            }
            .padding(.vertical, 4)
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

    private var divisionPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Assign Divisi", icon: "rectangle.stack.fill", color: .blue)

            Text("Divisi harus dibuat terlebih dahulu di menu Manage Divisions.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Menu {
                Button("Unassigned") { divisionName = "Unassigned" }
                ForEach(divisions) { div in
                    Button(div.name) { divisionName = div.name }
                }
            } label: {
                HStack {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    Text(divisionName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
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

    private var ownerInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 16))
            Text("Owner akan otomatis ditempatkan di channel General.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
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

    private func roleOption(_ role: Role, label: String, icon: String, color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.25)) { selectedRole = role }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(selectedRole == role ? 0.18 : 0.08))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.system(size: 15, weight: selectedRole == role ? .semibold : .regular))
                    .foregroundColor(selectedRole == role ? .primary : .secondary)
                Spacer()
                if selectedRole == role {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
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
}

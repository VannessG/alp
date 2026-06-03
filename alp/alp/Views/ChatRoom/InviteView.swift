//
//  InviteView.swift
//  alp
//
//  Created by Vincent on 02/06/26.
//
import SwiftUI

struct InviteView: View {
    @ObservedObject var roomVM: RoomViewModel
    let event: Event
    let availableUsers: [User]
    let currentUser: User?

    @Environment(\.dismiss) var dismiss
    @State private var roomName = ""
    @State private var selectedUserIds = Set<String>()

    private var selectedUsers: [User] {
        availableUsers.filter { user in
            guard let id = user.id else { return false }
            return selectedUserIds.contains(id)
        }
    }

    private var canSave: Bool {
        !roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedUserIds.isEmpty &&
        currentUser?.id != nil &&
        !roomVM.isCreatingRoom
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Room") {
                    TextField("Nama room", text: $roomName)
                        .textInputAutocapitalization(.words)
                }

                Section("Anggota Event") {
                    Menu {
                        if availableUsers.isEmpty {
                            Text("Tidak ada anggota lain")
                        } else {
                            ForEach(availableUsers) { user in
                                Button {
                                    toggleSelection(user)
                                } label: {
                                    Label(user.name, systemImage: isSelected(user) ? "checkmark.circle.fill" : "circle")
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedUsers.isEmpty ? "Pilih username" : "\(selectedUsers.count) anggota dipilih")
                                .foregroundColor(selectedUsers.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if selectedUsers.isEmpty {
                        Text("Pilih minimal satu anggota event. Kamu otomatis ikut di room ini.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(selectedUsers) { user in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.name)
                                        .font(.body)
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button {
                                    if let id = user.id {
                                        selectedUserIds.remove(id)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !roomVM.errorMessage.isEmpty {
                    Section {
                        Text(roomVM.errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Buat Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(roomVM.isCreatingRoom ? "Menyimpan..." : "Simpan") {
                        Task {
                            if let eventId = event.id {
                                let createdRoomId = await roomVM.createRoom(
                                    name: roomName,
                                    eventId: eventId,
                                    selectedUsers: selectedUsers,
                                    owner: currentUser
                                )
                                if createdRoomId != nil {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if roomName.isEmpty {
                    roomName = "Chat \(event.name)"
                }
            }
        }
    }

    private func isSelected(_ user: User) -> Bool {
        guard let id = user.id else { return false }
        return selectedUserIds.contains(id)
    }

    private func toggleSelection(_ user: User) {
        guard let id = user.id else { return }
        if selectedUserIds.contains(id) {
            selectedUserIds.remove(id)
        } else {
            selectedUserIds.insert(id)
        }
    }
}

//
//  RoomViewModel.swift
//  alp
//
//  Created by Vincent on 02/06/26.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class RoomViewModel: ObservableObject {
    @Published var rooms: [Room] = []
    @Published var errorMessage = ""
    @Published var isCreatingRoom = false
    private var listener: ListenerRegistration?
    private let service: RoomServiceProtocol

    init(service: RoomServiceProtocol = RoomService()) {
        self.service = service
    }

    func startListening(for userId: String, eventId: String) {
        listener?.remove()
        guard !userId.isEmpty, !eventId.isEmpty else {
            rooms = []
            return
        }

        listener = service.observeRooms(for: userId, eventId: eventId) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let fetchedRooms):
                    self?.rooms = fetchedRooms
                    self?.errorMessage = ""
                case .failure(let error):
                    self?.errorMessage = "Gagal memuat room: \(error.localizedDescription)"
                }
            }
        }
    }

    func createRoom(name: String, eventId: String, selectedUsers: [User], owner: User?) async -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Nama room wajib diisi."
            return nil
        }
        guard let owner = owner, owner.id != nil else {
            errorMessage = "User aktif tidak valid."
            return nil
        }
        guard !eventId.isEmpty else {
            errorMessage = "Event aktif tidak valid."
            return nil
        }
        guard !selectedUsers.isEmpty else {
            errorMessage = "Pilih minimal satu anggota event."
            return nil
        }

        isCreatingRoom = true
        defer { isCreatingRoom = false }

        do {
            let roomId = try await service.createRoom(name: trimmedName, eventId: eventId, participants: selectedUsers, owner: owner)
            errorMessage = ""
            return roomId
        } catch {
            errorMessage = "Gagal membuat room: \(error.localizedDescription)"
            return nil
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

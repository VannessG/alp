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
    private var listener: ListenerRegistration?

    func startListening(for userEmail: String) {
        listener?.remove()
        listener = RoomService().observeRooms(for: userEmail) { [weak self] result in
            switch result {
            case .success(let fetchedRooms):
                self?.rooms = fetchedRooms
            case .failure(let error):
                print("Gagal fetch rooms: \(error)")
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}


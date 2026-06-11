//
//  EventViewModel.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 29/05/26.
//

import SwiftUI
import Combine

@MainActor
class EventViewModel: ObservableObject {
    @Published var activeEvent: Event?
    @Published var userEvents: [Event] = []
    @Published var userEventsCount: Int = 0
    @Published var errorMessage = ""
    @Published var showBiometricError = false
    
    private let eventService: EventServiceProtocol
    private var cancelEventsListener: (() -> Void)?
    
    init(eventService: EventServiceProtocol? = nil) {
        self.eventService = eventService ?? EventService.shared
    }
    
    func fetchUserEvents(userId: String) {
        cancelEventsListener?()
        
        cancelEventsListener = eventService.observeUserEvents(userId: userId) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let events):
                    self.userEvents = events
                    self.userEventsCount = events.count
                    self.errorMessage = ""
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func createEvent(name: String, ownerId: String, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let event = try await self.eventService.createEvent(name: name, ownerId: ownerId)
                self.activeEvent = event
                completion(true)
            } catch {
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    func joinEvent(code: String, userId: String, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let event = try await self.eventService.joinEvent(code: code, userId: userId)
                self.activeEvent = event
                completion(true)
            } catch {
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    func updateAnnouncement(text: String) {
        guard let id = activeEvent?.id else { return }
        Task {
            do {
                try await self.eventService.updateAnnouncement(eventId: id, text: text)
                self.activeEvent?.announcement = text
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func endEvent() {
        guard let id = activeEvent?.id else { return }
        Task {
            do {
                try await self.eventService.endEvent(eventId: id)
                self.activeEvent?.status = "ended"
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteEventWithAuth() {
        Task {
            do {
                let reason = "Verifikasi identitas Anda untuk menghapus event ini."
                let isAuthorized = try await eventService.authenticateBiometrics(reason: reason)
                
                if isAuthorized {
                    if let id = activeEvent?.id {
                        try await self.eventService.deleteEvent(eventId: id)
                        self.activeEvent = nil
                    }
                } else {
                    self.showBiometricError = true
                }
            } catch {
                self.showBiometricError = true
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    deinit {
        cancelEventsListener?()
    }
}

//
//  EventMemberViewModel.swift
//  alp
//
//  Created by Lemuel on 29/05/26.
//

import SwiftUI
import Combine

@MainActor
class EventMemberViewModel: ObservableObject {
    @Published var members: [EventMember] = []
    @Published var currentUserRole: Role = .member
    @Published var currentUserDivision: String = "Unassigned"
    @Published var errorMessage = ""
    
    private let eventMemberService: EventMemberServiceProtocol
    private var cancelMembersListener: (() -> Void)?
    
    init(eventMemberService: EventMemberServiceProtocol? = nil) {
        self.eventMemberService = eventMemberService ?? EventMemberService.shared
    }
    
    func fetchMembers(for eventId: String, currentUserId: String?) {
        cancelMembersListener?()
        
        cancelMembersListener = eventMemberService.observeEventMembers(for: eventId) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let members):
                    self.members = members
                    
                    if let currentUserId = currentUserId,
                       let currentMember = self.members.first(where: { $0.userId == currentUserId }) {
                        self.currentUserRole = currentMember.role
                        self.currentUserDivision = currentMember.division
                    }
                    self.errorMessage = ""
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateMember(memberId: String, newRole: Role, newDivision: String, currentUserId: String?, eventId: String) {
        Task {
            do {
                try await self.eventMemberService.updateMemberRoleAndDivision(memberId: memberId, newRole: newRole, newDivision: newDivision)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func assignMemberToMyDivision(memberId: String, currentUserId: String?, eventId: String) {
        Task {
            do {
                try await self.eventMemberService.assignMemberToDivision(memberId: memberId, divisionName: currentUserDivision)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteEvent(eventId: String, activeEvent: inout Event?) {
        members.removeAll { $0.eventId == eventId }
        if activeEvent?.id == eventId {
            activeEvent = nil
        }
    }

    func getEligibleAssignees(activeEvent: Event?, registeredUsers: [User]) -> [User] {
        let eventMembers = getEventMembers(activeEvent: activeEvent)
        var eligibleMembers: [EventMember] = []
        
        if currentUserRole == .owner {
            eligibleMembers = eventMembers.filter { $0.role == .coordinator }
        } else if currentUserRole == .coordinator {
            eligibleMembers = eventMembers.filter { $0.role == .member && $0.division == currentUserDivision }
        }
        
        return eligibleMembers.compactMap { member in
            registeredUsers.first(where: { $0.id == member.userId })
        }
    }
    
    func getEventMembers(activeEvent: Event?) -> [EventMember] {
        guard let event = activeEvent else { return [] }
        return members.filter { $0.eventId == event.id }
    }
    
    deinit {
        cancelMembersListener?()
    }
}

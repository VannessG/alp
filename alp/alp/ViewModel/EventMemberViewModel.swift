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
    @Published var registeredUsers: [User] = []
    @Published var currentUserRole: Role = .member
    @Published var currentUserDivision: String = "Unassigned"
    @Published var errorMessage = ""

    private let eventMemberService: EventMemberServiceProtocol
    private let authService: AuthServiceProtocol
    private var cancelMembersListener: (() -> Void)?

    init(eventMemberService: EventMemberServiceProtocol? = nil, authService: AuthServiceProtocol? = nil) {
        self.eventMemberService = eventMemberService ?? EventMemberService.shared
        self.authService = authService ?? AuthService.shared
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
                       let currentMember = members.first(where: { $0.userId == currentUserId }) {
                        self.currentUserRole = currentMember.role
                        self.currentUserDivision = currentMember.division
                    }
                    self.errorMessage = ""
                    await self.fetchUsers(for: members)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func fetchUsers(for members: [EventMember]) async {
        let ids = members.map { $0.userId }
        do {
            let users = try await authService.fetchUsers(byIds: ids)
            self.registeredUsers = users
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func getUser(byId userId: String) -> User? {
        registeredUsers.first { $0.id == userId }
    }

    func updateMember(memberId: String, newRole: Role, newDivision: String) {
        Task {
            do {
                try await eventMemberService.updateMemberRoleAndDivision(memberId: memberId, newRole: newRole, newDivision: newDivision)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func getEventMembers(activeEvent: Event?) -> [EventMember] {
        guard let event = activeEvent else { return [] }
        return members.filter { $0.eventId == event.id }
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
            registeredUsers.first { $0.id == member.userId }
        }
    }

    deinit {
        cancelMembersListener?()
    }
}

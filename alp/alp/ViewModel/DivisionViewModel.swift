//
//  DivisionViewModel.swift
//  alp
//
//  Created by Lemuel on 29/05/26.
//

import SwiftUI
import Combine

@MainActor
class DivisionViewModel: ObservableObject {
    @Published var divisions: [Division] = []
    @Published var members: [EventMember] = []
    @Published var errorMessage = ""
    
    private let divisionService: DivisionServiceProtocol
    private var cancelDivisionsListener: (() -> Void)?
    
    init(divisionService: DivisionServiceProtocol? = nil) {
        self.divisionService = divisionService ?? DivisionService.shared
    }
    
    func fetchDivisions(for eventId: String) {
        cancelDivisionsListener?()
        
        cancelDivisionsListener = divisionService.observeDivisions(for: eventId) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let divisions):
                    self.divisions = divisions
                    self.errorMessage = ""
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func getEventDivisions(activeEvent: Event?) -> [String] {
        guard let event = activeEvent else { return [] }
        let divs = members.filter { $0.eventId == event.id && $0.division != "Unassigned" && $0.division != "General" }.map { $0.division }
        return Array(Set(divs)).sorted()
    }
    
    func addDivision(name: String, activeEvent: Event?) {
        guard let eventId = activeEvent?.id else { return }
        let isExist = divisions.contains {
            $0.eventId == eventId && $0.name.lowercased() == name.lowercased()
        }
        
        if !isExist && !name.isEmpty {
            Task {
                do {
                    try await self.divisionService.addDivision(name: name, eventId: eventId)
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateDivision(divisionId: String, newName: String, activeEvent: Event?) {
        if let index = divisions.firstIndex(where: { $0.id == divisionId }) {
            let oldName = divisions[index].name
            
            Task {
                do {
                    try await self.divisionService.updateDivisionName(divisionId: divisionId, newName: newName)
                    
                    for i in 0..<self.members.count {
                        if self.members[i].eventId == activeEvent?.id && self.members[i].division == oldName {
                            self.members[i].division = newName
                        }
                    }
                    self.errorMessage = ""
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteDivision(divisionId: String, activeEvent: Event?) {
        if let index = divisions.firstIndex(where: { $0.id == divisionId }) {
            let divName = divisions[index].name
            
            Task {
                do {
                    try await self.divisionService.deleteDivision(divisionId: divisionId)
                    
                    for i in 0..<self.members.count {
                        if self.members[i].division == divName {
                            self.members[i].division = "Unassigned"
                        }
                    }
                    self.errorMessage = ""
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func getActiveEventDivisions(activeEvent: Event?) -> [Division] {
        guard let eventId = activeEvent?.id else { return [] }
        return divisions.filter { $0.eventId == eventId }
    }
    
    deinit {
        cancelDivisionsListener?()
    }
}

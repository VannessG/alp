//
//  ManageDivisionView.swift
//  alp
//
//  Created by Lemuel on 02/06/26.
//

import SwiftUI

struct ManageDivisionView: View {
    @EnvironmentObject var divisionVM: DivisionViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    @State private var newDivisionName = ""
    @State private var editingDivision: Division? = nil
    @State private var updatedName = ""
    @State private var divisionToDelete: Division? = nil
    @State private var showDeleteConfirm = false

    private var activeEvent: Event? { eventVM.activeEvent }
    private var isReadOnly: Bool { activeEvent?.status == "ended" }

    private var divisions: [Division] {
        divisionVM.getActiveEventDivisions(activeEvent: activeEvent)
    }

    private var isDuplicate: Bool {
        let trimmed = newDivisionName.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return false }
        return divisions.contains {
            $0.name.trimmingCharacters(in: .whitespaces).lowercased() == trimmed
        }
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if !isReadOnly {
                        addDivisionCard
                    }
                    divisionListCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: 650)
                .scaleEffect(sizeClass == .regular ? 1.55 : 1.0, anchor: .top)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, sizeClass == .regular ? 450 : 0)
            }
        }
        .navigationTitle("Manage Divisions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let eventId = activeEvent?.id {
                divisionVM.fetchDivisions(for: eventId)
            }
        }
        .alert("Edit Nama Divisi", isPresented: Binding(
            get: { editingDivision != nil },
            set: { if !$0 { editingDivision = nil } }
        )) {
            TextField("Nama Baru", text: $updatedName)
            Button("Batal", role: .cancel) { editingDivision = nil }
            Button("Simpan") {
                if let div = editingDivision, let id = div.id {
                    let trimmed = updatedName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        divisionVM.updateDivision(divisionId: id, newName: trimmed, activeEvent: activeEvent)
                    }
                }
                editingDivision = nil
            }
        }
        .alert("Hapus Divisi", isPresented: $showDeleteConfirm) {
            Button("Batal", role: .cancel) { divisionToDelete = nil }
            Button("Hapus", role: .destructive) {
                if let div = divisionToDelete, let id = div.id {
                    divisionVM.deleteDivision(divisionId: id, activeEvent: activeEvent)
                }
                divisionToDelete = nil
            }
        } message: {
            if let div = divisionToDelete {
                Text("Anggota di divisi \"\(div.name)\" akan menjadi Unassigned. Aksi ini tidak dapat dibatalkan.")
            }
        }
    }

    private var addDivisionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Tambah Divisi Baru", icon: "plus.circle.fill", color: .blue)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    TextField("Nama Divisi (misal: Konsumsi)", text: $newDivisionName)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isDuplicate ? Color.red.opacity(0.5) : Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )

                    Button {
                        let clean = newDivisionName.trimmingCharacters(in: .whitespaces)
                        divisionVM.addDivision(name: clean, activeEvent: activeEvent)
                        newDivisionName = ""
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    (newDivisionName.trimmingCharacters(in: .whitespaces).isEmpty || isDuplicate)
                                        ? Color(UIColor.systemGray5)
                                        : Color.blue
                                )
                                .frame(width: 40, height: 40)
                                .shadow(
                                    color: (newDivisionName.trimmingCharacters(in: .whitespaces).isEmpty || isDuplicate)
                                        ? .clear : Color.blue.opacity(0.3),
                                    radius: 6, y: 3
                                )
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(
                                    (newDivisionName.trimmingCharacters(in: .whitespaces).isEmpty || isDuplicate)
                                        ? .secondary : .white
                                )
                        }
                    }
                    .disabled(newDivisionName.trimmingCharacters(in: .whitespaces).isEmpty || isDuplicate)
                }

                if isDuplicate {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                        Text("Divisi dengan nama ini sudah ada.")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
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

    private var divisionListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Daftar Divisi", icon: "list.bullet", color: .blue)

            if divisions.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.5))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Belum ada divisi")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Tambahkan divisi untuk mulai mengorganisir anggota.")
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
                    ForEach(divisions) { division in
                        divisionRow(division)
                    }
                }
            }

            if !divisionVM.errorMessage.isEmpty {
                Text(divisionVM.errorMessage)
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

    private func divisionRow(_ division: Division) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.blue)
            }

            Text(division.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            if !isReadOnly {
                HStack(spacing: 8) {
                    Button {
                        editingDivision = division
                        updatedName = division.name
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        divisionToDelete = division
                        showDeleteConfirm = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
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
}

#Preview {
    let mockEvent = EventViewModel()
    mockEvent.activeEvent = Event(
        id: "event_1",
        name: "Kepanitiaan SIFT",
        joinCode: "SIFT26",
        announcement: "",
        ownerId: "123",
        status: "active",
        members: ["123"]
    )

    let mockDivision = DivisionViewModel()
    mockDivision.divisions = [
        Division(id: "d1", eventId: "event_1", name: "Konsumsi"),
        Division(id: "d2", eventId: "event_1", name: "Dekorasi"),
        Division(id: "d3", eventId: "event_1", name: "Dokumentasi")
    ]

    return NavigationStack {
        ManageDivisionView()
            .environmentObject(mockDivision)
            .environmentObject(mockEvent)
    }
}

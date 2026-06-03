//
//  ChatView.swift
//  alp
//
//  Created by Vincent on 02/06/26.
//
import SwiftUI
import Foundation
import Combine

struct ChatView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var memberVM: EventMemberViewModel
    @StateObject var roomVM = RoomViewModel()
    @State private var showInvite = false

    var body: some View {
        NavigationStack {
            Group {
                            if eventVM.activeEvent == nil {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 50))
                                        .foregroundColor(.secondary)
                                    Text("Event belum dipilih")
                                        .font(.title2).bold()
                                    Text("Pilih event terlebih dahulu untuk membuka chat.")
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            } else if roomVM.rooms.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 50))
                                        .foregroundColor(.secondary)
                                    Text("Belum ada room")
                                        .font(.title2).bold()
                                    Text("Buat room baru untuk mulai berdiskusi dengan anggota event.")
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            } else {
                                List(roomVM.rooms) { room in
                                    NavigationLink(destination: ChatRoomView(roomId: room.id ?? "").environmentObject(authVM)) {
                                        roomRow(room)
                                    }
                                }
                                .listStyle(.plain)
                            }
                        }            .navigationTitle(eventVM.activeEvent?.name ?? "Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInvite = true }) {
                        Image(systemName: "plus")
                    }
                    .disabled(eventVM.activeEvent?.id == nil)
                }
            }
            .sheet(isPresented: $showInvite) {
                if let event = eventVM.activeEvent {
                    InviteView(
                        roomVM: roomVM,
                        event: event,
                        availableUsers: selectableUsers,
                        currentUser: authVM.currentUser
                    )
                    .environmentObject(authVM)
                }
            }
            .onAppear {
                loadChatData()
            }
            .onDisappear { roomVM.stopListening() }
        }
    }

    private var selectableUsers: [User] {
        memberVM.registeredUsers
            .filter { $0.id != authVM.currentUser?.id }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func roomRow(_ room: Room) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(hasUnread(room) ? Color.blue.opacity(0.15) : Color.gray.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(hasUnread(room) ? .blue : .secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(room.name)
                        .font(.headline)
                        .lineLimit(1)
                    if hasUnread(room) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(room.lastMessage?.isEmpty == false ? room.lastMessage ?? "" : participantSummary(room))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let date = room.lastTimestamp {
                Text(shortTime(date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadChatData() {
        guard let eventId = eventVM.activeEvent?.id,
              let userId = authVM.currentUser?.id else {
            roomVM.rooms = []
            return
        }

        memberVM.fetchMembers(for: eventId, currentUserId: userId)
        roomVM.startListening(for: userId, eventId: eventId)
    }

    private func participantSummary(_ room: Room) -> String {
        let currentUserName = authVM.currentUser?.name ?? ""
        let others = room.participantNames.filter { $0 != currentUserName }
        if others.isEmpty {
            return "Hanya kamu"
        }
        return others.joined(separator: ", ")
    }

    private func hasUnread(_ room: Room) -> Bool {
        guard let userId = authVM.currentUser?.id,
              let lastTimestamp = room.lastTimestamp,
              room.lastMessage?.isEmpty == false else {
            return false
        }

        guard let readAt = room.readBy?[userId] else {
            return true
        }

        return lastTimestamp > readAt
    }

    private func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "dd/MM"
        return formatter.string(from: date)
    }
}

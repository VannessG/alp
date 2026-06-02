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
    @StateObject var roomVM = RoomViewModel()
    @State private var showInvite = false

    var body: some View {
        NavigationStack {
            List(roomVM.rooms) { room in
                NavigationLink(destination: ChatRoomView(roomId: room.id ?? "").environmentObject(authVM)) {
                    VStack(alignment: .leading) {
                        let otherParticipants = room.participants.filter { $0 != authVM.currentUser?.email }
                        Text(otherParticipants.joined(separator: ", "))
                            .font(.headline)

                        Text(room.lastMessage ?? "Belum ada pesan")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(authVM.currentUser?.name ?? "Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInvite = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showInvite) {
                InviteView().environmentObject(authVM)
            }
            .onAppear { roomVM.startListening(for: authVM.currentUser?.email ?? "") }
            .onDisappear { roomVM.stopListening() }
        }
    }
}

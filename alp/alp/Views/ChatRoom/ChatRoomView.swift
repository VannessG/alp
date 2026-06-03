//
//  ChatRoomView.swift
//  alp
//
//  Created by Vincent on 02/06/26.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

struct ChatRoomView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject var vm = ChatViewModel()
    let roomId: String
    @State private var text = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(vm.messages) { msg in
                    VStack(alignment: msg.senderId == authVM.currentUser?.id ? .trailing : .leading) {
                        if msg.senderId != authVM.currentUser?.id {
                            Text(msg.senderName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(msg.text)
                            .padding()
                            .background(msg.senderId == authVM.currentUser?.id ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(msg.senderId == authVM.currentUser?.id ? .white : .black)
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, alignment: msg.senderId == authVM.currentUser?.id ? .trailing : .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 2)
                }
            }
        }
            HStack {
                TextField("Tulis pesan...", text: $text)
                Button("Kirim") {
                    Task {
                        await vm.sendMessage(
                            roomId: roomId,
                            senderId: authVM.currentUser?.id ?? "unknown",
                            senderName: authVM.currentUser?.name ?? "Anon",
                            text: text
                        )
                        text = ""
                    }
                }
        }
            .onAppear {
                vm.startListening(
                    roomId: roomId,
                    userId: authVM.currentUser?.id ?? ""
                )
            }
        .onDisappear { vm.stopListening() }
    }
}


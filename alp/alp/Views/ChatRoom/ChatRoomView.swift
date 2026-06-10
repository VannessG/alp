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
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.messages) { msg in
                            messageRow(msg)
                                .id(messageId(msg))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onAppear {
                    vm.startListening(
                        roomId: roomId,
                        userId: authVM.currentUser?.id ?? ""
                    )
                    scrollToLastMessage(with: proxy)
                }
                .onChange(of: vm.messages) { _ in
                    scrollToLastMessage(with: proxy)
                }
            }

            Divider()

            HStack(spacing: 10) {
                TextField("Tulis pesan...", text: $text)
                    .textFieldStyle(.roundedBorder)

                Button(vm.isSending ? "Mengirim..." : "Kirim") {
                    Task {
                        let sent = await vm.sendMessage(
                            roomId: roomId,
                            senderId: authVM.currentUser?.id ?? "unknown",
                            senderName: authVM.currentUser?.name ?? "Anon",
                            text: text
                        )
                        if sent {
                            text = ""
                        }
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSending)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onDisappear { vm.stopListening() }
    }

    private func messageRow(_ msg: ChatMessage) -> some View {
        let isCurrentUser = msg.senderId == authVM.currentUser?.id

        return VStack(alignment: isCurrentUser ? .trailing : .leading) {
            if !isCurrentUser {
                Text(msg.senderName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(msg.text)
                .padding()
                .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isCurrentUser ? .white : .black)
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
        .padding(.horizontal)
        .padding(.vertical, 2)
    }

    private func messageId(_ message: ChatMessage) -> String {
        message.id ?? "\(message.roomId)-\(message.senderId)-\(message.timestamp?.timeIntervalSince1970 ?? 0)"
    }

    private func scrollToLastMessage(with proxy: ScrollViewProxy) {
        guard let lastMessage = vm.messages.last else { return }

        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(messageId(lastMessage), anchor: .bottom)
            }
        }
    }
}

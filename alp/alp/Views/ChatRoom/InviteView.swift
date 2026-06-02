//
//  InviteView.swift
//  alp
//
//  Created by Vincent on 02/06/26.
//
import SwiftUI
import Foundation
import Combine
import FirebaseFirestore

struct InviteView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var emails: [String] = [""]
    @State private var createdRoomId: String?
    @State private var navigateToChat = false
    
    var body: some View {
        NavigationStack {
            Form {
                ForEach(emails.indices, id: \.self) { i in
                    TextField("Email anggota", text: $emails[i])
                }
                Button("Tambah Email") { emails.append("") }
            }
            .navigationTitle("Buat Room")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        do {
                            let roomRef = try Firestore.firestore().collection("rooms").addDocument(data: [
                                "participants": emails.filter { !$0.isEmpty },
                                "createdAt": Timestamp(date: Date()),
                                "owner": authVM.currentUser?.email ?? "" 
                            ])
                            createdRoomId = roomRef.documentID
                            navigateToChat = true
                        } catch {
                            print("Gagal membuat room: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToChat) {
                ChatRoomView(roomId: createdRoomId ?? "")
            }
        }
    }
}

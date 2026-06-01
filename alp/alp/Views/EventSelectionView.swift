//
//  EventSelectionView.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 02/06/26.
//

import SwiftUI

struct EventSelectionView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    @State private var isDashboardActive = false
    @State private var showCreate = false
    @State private var newEventName = ""
    @State private var showJoin = false
    @State private var joinCode = ""
    @State private var showLogoutWarning = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background layar
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // ==========================================
                        // 1. WELCOME HERO SECTION
                        // ==========================================
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            HStack(alignment: .center, spacing: 0) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Halo,")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(authVM.currentUser?.name ?? "User")
                                        .font(.system(size: 25, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                }
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 22)
                                
                                Spacer()
                                
                                let count = eventVM.userEvents.count
                                VStack(spacing: 4) {
                                    Spacer()
                                    Text("\(count)")
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                    Text(count <= 1 ? "event" : "events")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                }
                                .frame(width: 80)
                                .frame(maxHeight: .infinity)
                                .background(Color.white.opacity(0.2))
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 0,
                                        bottomLeadingRadius: 0,
                                        bottomTrailingRadius: 20,
                                        topTrailingRadius: 20
                                    )
                                )
                            }
                            .padding(.leading, 20)
                        }
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        .frame(height: 110)
                        
                        
                        // ==========================================
                        // 2. EVENT LIST SECTION
                        // ==========================================
                        VStack(spacing: 12) {
                            HStack {
                                // Section Header Inline
                                HStack(spacing: 7) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.blue)
                                        .frame(width: 3, height: 16)
                                    Image(systemName: "list.bullet.below.rectangle")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.blue)
                                    Text("Kepanitiaan Saya")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(0.6)
                                }
                            }
                            
                            if eventVM.userEvents.isEmpty {
                                // Empty State
                                VStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                        Image(systemName: "tray")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundStyle(.blue)
                                    }
                                    VStack(spacing: 4) {
                                        Text("Belum ada kepanitiaan")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("Buat atau gabung event untuk memulai.")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 36)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            } else {
                                // Event List
                                VStack(spacing: 12) {
                                    ForEach(eventVM.userEvents) { event in
                                        Button(action: {
                                            eventVM.activeEvent = event
                                            isDashboardActive = true
                                        }) {
                                            HStack(spacing: 14) {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                                        .fill(Color.blue)
                                                        .frame(width: 46, height: 46)
                                                    Image(systemName: "flag.fill")
                                                        .foregroundColor(.white)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(event.name)
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundColor(.primary)
                                                    
                                                    let role = (event.ownerId == authVM.currentUser?.id) ? "Owner" : "Member"
                                                    Text("Sebagai \(role)")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(14)
                                            .background(Color(UIColor.secondarySystemGroupedBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        
                        // ==========================================
                        // 3. ACTION SECTION
                        // ==========================================
                        VStack(spacing: 10) {
                            // Section Header Inline
                            HStack(spacing: 7) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.blue)
                                    .frame(width: 3, height: 16)
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.blue)
                                Text("Mulai")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.6)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Button Create Event
                            Button(action: { showCreate = true }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("Buat Event Baru")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Kamu akan menjadi owner")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 18).padding(.vertical, 14)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                            }
                            
                            // Button Join Event
                            Button(action: { showJoin = true }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.blue)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("Gabung Event")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("Masukkan kode undangan")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 18).padding(.vertical, 14)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            }
                        }
                        
                    }
                    .padding(.horizontal, 16)
                    
                    // Padding dasar
                    .padding(.vertical, 24)
                    
                    // Batasi lebar
                    .frame(maxWidth: 650)
                    
                    // Scale effect untuk iPad
                    .scaleEffect(sizeClass == .regular ? 1.55 : 1.0, anchor: .top)
                    
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Padding ekstra untuk scroll iPad
                    .padding(.bottom, sizeClass == .regular ? 350 : 0)
                }
            }
            .navigationTitle("Event Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showLogoutWarning = true }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationDestination(isPresented: $isDashboardActive) {
                DashboardView()
            }
            .onAppear {
                if let userId = authVM.currentUser?.id {
                    eventVM.fetchUserEvents(userId: userId)
                }
            }
            // Alert Create Event
            .alert("Buat Event", isPresented: $showCreate) {
                TextField("Nama Event", text: $newEventName)
                Button("Batal", role: .cancel) { }
                Button("Buat") {
                    eventVM.createEvent(name: newEventName, ownerId: authVM.currentUser?.id ?? "") { success in
                        if success {
                            isDashboardActive = true
                        }
                    }
                }
            }
            // Alert Join Event
            .alert("Join Event", isPresented: $showJoin) {
                TextField("Kode Join", text: $joinCode)
                Button("Batal", role: .cancel) { }
                Button("Join") {
                    eventVM.joinEvent(code: joinCode, userId: authVM.currentUser?.id ?? "") { success in
                        if success { isDashboardActive = true }
                    }
                }
            }
            // Alert Logout Warning
            .alert("Konfirmasi Logout", isPresented: $showLogoutWarning) {
                Button("Batal", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    authVM.logout()
                }
            } message: {
                Text("Apakah Anda yakin ingin keluar dari akun ini?")
            }
        }
        .preferredColorScheme(.light)
    }
}


// MARK: - Preview Langsung Tanpa Struct Tambahan
#Preview {
    let mockAuth = AuthViewModel()
    mockAuth.currentUser = User(id: "123", name: "Vanness", email: "test@test.com")
    
    let mockEvent = EventViewModel()
    // Data tiruan untuk mengetes list
    mockEvent.userEvents = [
        Event(id: "1", name: "Kepanitiaan SIFT", joinCode: "SF123", announcement: "", ownerId: "123", status: "active", members: []),
        Event(id: "2", name: "PRISM 2026", joinCode: "PR999", announcement: "", ownerId: "456", status: "active", members: [])
    ]
    mockEvent.userEventsCount = 2
    
    return EventSelectionView()
        .environmentObject(mockAuth)
        .environmentObject(mockEvent)
}

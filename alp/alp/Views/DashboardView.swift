//
//  DashboardView.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 02/06/26.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @State private var showAnnouncementInput = false
    @State private var announcementText = ""
    @State private var showLogoutWarning = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                if let event = eventVM.activeEvent {
                    let isReadOnly = (event.status == "ended")
                    let role = (event.ownerId == authVM.currentUser?.id) ? "Owner" : "Member"
                    
                    VStack(spacing: 24) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            VStack(spacing: 0) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("ACTIVE COMMITTEE")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.7))
                                            .tracking(0.8)
                                        
                                        Text(event.name)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                        
                                        Text(role.uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.white)
                                            .clipShape(Capsule())
                                            .padding(.top, 4)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 22)
                                
                                Spacer(minLength: 20)
                                
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "key.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                        Text(event.joinCode)
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                                    
                                    Spacer()
                                    
                                    if event.status == "ended" {
                                        Text("ENDED")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.red.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                        }
                        .frame(height: 160)
                        .padding(.horizontal, 16)
                        .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        
                        VStack(spacing: 20) {
                            VStack(spacing: 12) {
                                HStack {
                                    HStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: 2).fill(Color.orange).frame(width: 3, height: 16)
                                        Image(systemName: "megaphone.fill").font(.system(size: 12, weight: .semibold)).foregroundColor(.orange)
                                        Text("Pengumuman").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).textCase(.uppercase).tracking(0.5)
                                    }
                                    Spacer()
                                    if !isReadOnly {
                                        Button(action: {
                                            announcementText = event.announcement
                                            showAnnouncementInput = true
                                        }) {
                                            Text(event.announcement.isEmpty ? "Tambah" : "Edit")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(Color.orange.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color.orange.opacity(0.15)).frame(width: 36, height: 36)
                                        Image(systemName: "bell.badge.fill").font(.system(size: 15, weight: .semibold)).foregroundColor(.orange)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        if event.announcement.isEmpty {
                                            Text("Belum ada pengumuman.")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .italic()
                                        } else {
                                            Text(event.announcement)
                                                .font(.system(size: 14))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    .padding(.top, 8)
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                            }
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 2).fill(Color.blue).frame(width: 3, height: 16)
                                    Image(systemName: "square.grid.2x2.fill").font(.system(size: 12, weight: .semibold)).foregroundColor(.blue)
                                    Text("Menu Operasional").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).textCase(.uppercase).tracking(0.5)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 12) {
                                    Button(action: {}) {
                                        VStack(spacing: 10) {
                                            ZStack {
                                                Circle().fill(Color.blue.opacity(0.15)).frame(width: 54, height: 54)
                                                Image(systemName: "person.3.fill").font(.system(size: 22, weight: .semibold)).foregroundColor(.blue)
                                            }
                                            Text("Divisions")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                    }.buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {}) {
                                        VStack(spacing: 10) {
                                            ZStack {
                                                Circle().fill(Color.green.opacity(0.15)).frame(width: 54, height: 54)
                                                Image(systemName: "list.bullet.rectangle.portrait.fill").font(.system(size: 22, weight: .semibold)).foregroundColor(.green)
                                            }
                                            Text("Members")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                    }.buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {}) {
                                        VStack(spacing: 10) {
                                            ZStack {
                                                Circle().fill(Color.purple.opacity(0.15)).frame(width: 54, height: 54)
                                                Image(systemName: "checkmark.square.fill").font(.system(size: 22, weight: .semibold)).foregroundColor(.purple)
                                            }
                                            Text("Presence")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                    }.buttonStyle(PlainButtonStyle())
                                    
                                }
                            }
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 2).fill(Color.blue).frame(width: 3, height: 16)
                                    Image(systemName: "calendar").font(.system(size: 12, weight: .semibold)).foregroundColor(.blue)
                                    Text("Upcoming Schedule").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).textCase(.uppercase).tracking(0.5)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Tidak ada jadwal terdekat")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("Jadwal yang akan datang tampil di sini.")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                            }
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                                    Text("DANGER ZONE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                        .tracking(0.8)
                                        .fixedSize()
                                    Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                                }
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                                
                                if !isReadOnly {
                                    Button(action: { eventVM.endEvent() }) {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.orange.opacity(0.15)).frame(width: 40, height: 40)
                                                Image(systemName: "stop.circle.fill").font(.system(size: 18, weight: .semibold)).foregroundColor(.orange)
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("End Event").font(.system(size: 15, weight: .semibold)).foregroundColor(.orange)
                                                Text("Event akan diubah menjadi Read-Only").font(.system(size: 12)).foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                                        }
                                        .padding(14)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                    }.buttonStyle(PlainButtonStyle())
                                } else {
                                    Text("EVENT TELAH BERAKHIR (Read Only)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.red)
                                        .padding(.vertical, 8)
                                }
                                
                                Button(action: {
                                    eventVM.deleteEvent {
                                        dismiss()
                                    }
                                }) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.red.opacity(0.15)).frame(width: 40, height: 40)
                                            Image(systemName: "trash.fill").font(.system(size: 18, weight: .semibold)).foregroundColor(.red)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Delete Event").font(.system(size: 15, weight: .semibold)).foregroundColor(.red)
                                            Text("Semua data akan terhapus permanen").font(.system(size: 12)).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                                    }
                                    .padding(14)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                }.buttonStyle(PlainButtonStyle())
                            }
                            
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: 650)
                    .scaleEffect(sizeClass == .regular ? 1.55 : 1.0, anchor: .top)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, sizeClass == .regular ? 450 : 0)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold))
                        Text("Back to Lobby").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showLogoutWarning = true }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Pengumuman", isPresented: $showAnnouncementInput) {
            TextField("Isi pengumuman", text: $announcementText)
            Button("Batal", role: .cancel) { }
            Button("Simpan") {
                eventVM.updateAnnouncement(text: announcementText)
            }
        }
        .alert("Konfirmasi Logout", isPresented: $showLogoutWarning) {
            Button("Batal", role: .cancel) { }
            Button("Logout", role: .destructive) {
                authVM.logout()
            }
        } message: {
            Text("Apakah Anda yakin ingin keluar dari akun ini?")
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    let mockAuth = AuthViewModel()
    mockAuth.currentUser = User(id: "123", name: "Vanness", email: "test@test.com")
    
    let mockEvent = EventViewModel()
    mockEvent.activeEvent = Event(
        id: "event_1",
        name: "Kepanitiaan SIFT",
        joinCode: "SIFT26",
        announcement: "Rapat perdana besok jam 10 pagi di lab mac.",
        ownerId: "123",
        status: "active",
        members: ["123"]
    )
    
    return NavigationStack {
        DashboardView()
            .environmentObject(mockAuth)
            .environmentObject(mockEvent)
    }
}

//
//  alpApp.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 29/05/26.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure() // <-- Wajib ada
        return true
    }
}

@main
struct alpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authVM = AuthViewModel()
    @StateObject var eventVM = EventViewModel()
    
    var body: some Scene {
        WindowGroup {
            // Logika pindah halaman otomatis
            if authVM.isAuthenticated {
                EventSelectionView()
                    .environmentObject(authVM)
                    .environmentObject(eventVM)
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
    }
}

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
        FirebaseApp.configure()
        return true
    }
}

@main
struct alpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authVM = AuthViewModel()
    @StateObject var eventVM = EventViewModel()
    @StateObject var memberVM = EventMemberViewModel()
    @StateObject var divisionVM = DivisionViewModel()
    @StateObject var attendanceVM = AttendanceViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(eventVM)
                .environmentObject(memberVM)
                .environmentObject(divisionVM)
                .environmentObject(attendanceVM)
        }
    }
}

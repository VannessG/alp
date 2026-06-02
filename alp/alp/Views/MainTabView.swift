//
//  MainTabView.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 02/06/26.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
        }
        .tint(.blue)
    }
}

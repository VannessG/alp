//
//  ContentView.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 29/05/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    
    var body: some View {
        Group {
            if authVM.currentUser == nil {
                LoginView()
            } else if eventVM.activeEvent == nil {
                EventSelectionView()
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}

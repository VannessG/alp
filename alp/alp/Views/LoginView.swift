//
//  LoginView.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 02/06/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Selamat Datang")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text("Silakan masuk ke akun Anda")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            SecureField("Password", text: $password)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        
                        if !authVM.errorMessage.isEmpty {
                            Text(authVM.errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                        
                        Button(action: {
                            authVM.login(email: email, pass: password)
                        }) {
                            Text("Masuk")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    HStack(spacing: 5) {
                        Text("Belum punya akun?")
                            .foregroundColor(.secondary)
                        Button(action: {
                            showRegister = true
                        }) {
                            HStack(spacing: 4) {
                                
                                Text("Daftar sekarang")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            .font(.system(size: 14))
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: 450)
                .scaleEffect(sizeClass == .regular ? 1.55 : 1.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

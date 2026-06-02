//
//  RegisterView.swift
//  alp
//
//  Created by Vanness Aurelius Gunawan on 02/06/26.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 12) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Buat Akun Baru")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text("Lengkapi data di bawah untuk mendaftar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            TextField("Nama Lengkap", text: $name)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        
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
                            authVM.register(name: name, email: email, pass: password)
                        }) {
                            Text("Daftar")
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
                }
                .frame(maxWidth: 450)
                .scaleEffect(sizeClass == .regular ? 1.55 : 1.0)
                .padding(.vertical, sizeClass == .regular ? 100 : 0)
                
                Spacer()
                
                HStack(spacing: 5) {
                    Text("Sudah punya akun?")
                        .foregroundColor(.secondary)
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Text("Masuk di sini")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .font(.system(size: 14))
                    }
                }
                .scaleEffect(sizeClass == .regular ? 1.3 : 1.0)
                .padding(.bottom, sizeClass == .regular ? 40 : 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
}

//
//  SettingView.swift
//  Stubet
//
//  Created by KJ on 11/18/24.
//

import SwiftUI

struct SettingView: View {
    
    @StateObject private var accountManager = AccountManager.shared
    @State private var showLogoutAlert = false
    
    var body: some View {
        VStack {
            Button {
                showLogoutAlert = true
            } label: {
                Text("サインアウト")
                    .foregroundColor(.red)
                    .padding(8)
                    .background(.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.top)
            Spacer()
        }
        .alert("サインアウト", isPresented: $showLogoutAlert, actions: {
                Button("キャンセル", role: .cancel) { }
                Button("サインアウト", role: .destructive) {
                    Task {
                        try await signout()
                    }
                }
            }, message: {
                Text("本当にサインアウトしますか？")
            })
        .navigationTitle("設定")
    }
    
    private func signout() async throws {
        do {
            BetManager.shared.emptyAllData()
            FriendManager.shared.emptyAllData()
            try await accountManager.signOut()
        } catch {
            print(error)
        }
    }
}

#Preview {
    SettingView()
}

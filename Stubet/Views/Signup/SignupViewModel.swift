//
//  SignupViewModel.swift
//  Stubet
//
//  Created by HAGIHARA KADOSHIMA on 2024/09/05.
//

import SwiftUI
import Combine
import FirebaseAuth
import Foundation
import FirebaseFirestore

class SignupViewModel: ObservableObject {
    @Published var username = ""
    @Published var displayName = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var iconImage: UIImage?
    @Published var iconImageUrl: URL?
    
    @Published var showError = false
    @Published var errorMessage = ""
    
    // バリデーションエラーメッセージ用のプロパティ
    @Published var usernameError: String = ""
    @Published var emailError: String = ""
    @Published var passwordError: String = ""
    @Published var confirmPasswordError: String = ""
    
    @Published var isLoading = false
    
    let db = Firestore.firestore()

    init() {
        // 必要に応じて、初期値を設定
    }
        
    @MainActor
    func signup() async throws {
        // エラーがなければ続行
        if usernameError.isEmpty && emailError.isEmpty && passwordError.isEmpty && confirmPasswordError.isEmpty {
           
            // TODO：ユーザーネームとパスワードの画面とそれ以外の詳細入力画面を分ける
            
            isLoading = true
            
            if let _ = self.iconImage {
                iconImageUrl = try await AccountManager.shared
                    .uploadIconImage(iconImage: iconImage)
                print("Profile image uploaded to: \(iconImageUrl!)")
            }
            // サインアップする
            try await AccountManager.shared
                .signUp(
                    password: password,
                    userName: username,
                    displayName: displayName,
                    iconImageUrl: iconImageUrl
                )
            
            isLoading = false
            
        } else {
            showError = true
            errorMessage = "Please fix the errors above."
        }
    }
    
    @MainActor
    func checkUsernameAvailability() async {
        guard !username.isEmpty else {
            usernameError = ""
            return
        }

        isLoading = true // Start loading
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("username", isEqualTo: username)
                .getDocuments()

            if !snapshot.documents.isEmpty {
                usernameError = "このユーザー名はすでに使用されています。"
            } else {
                usernameError = ""
            }
        } catch {
            print("Error checking username: \(error.localizedDescription)")
            usernameError = "エラーが発生しました。"
        }
        
        isLoading = false // stop loading
    }
}

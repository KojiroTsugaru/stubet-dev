//
//  SignupView.swift
//  Stubet
//
//  Created by HAGIHARA KADOSHIMA on 2024/09/05.
//
import Foundation
import SwiftUI
import PhotosUI

struct SignupView: View {
    @Binding var showSignupView: Bool
    @ObservedObject var viewModel = SignupViewModel()

    var body: some View {
        ZStack {
            VStack {
                // アイコン画像の選択
                IconPhotoPickerView(viewModel: viewModel)

                // ディスプレイ名入力フィールドとエラーメッセージ
                VStack(alignment: .leading, spacing: 5) {
                    TextField("名前", text: $viewModel.displayName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                        .padding(.horizontal)
                    
                    if viewModel.usernameError != "" {
                        Text(viewModel.usernameError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 16)
                    }
                }
                .padding(.bottom, 10) // 各フィールドの間に隙間を追加
                
                // ユーザー名入力フィールドとエラーメッセージ
                VStack(alignment: .leading, spacing: 5) {
                    TextField("ユーザーネーム", text: $viewModel.username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                        .padding(.horizontal)
                    
                    if viewModel.usernameError != "" {
                        Text(viewModel.usernameError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 16)
                    }
                }
                .padding(.bottom, 10) // 各フィールドの間に隙間を追加

                // パスワード入力フィールドとエラーメッセージ
                VStack(alignment: .leading, spacing: 5) {
                    SecureField("パスワード", text: $viewModel.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                        .padding(.horizontal)
                    
                    if viewModel.passwordError != "" {
                        Text(viewModel.passwordError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 16)
                    }
                }
                .padding(.bottom, 10)

                // パスワード確認入力フィールドとエラーメッセージ
                VStack(alignment: .leading, spacing: 5) {
                    SecureField("パスワード確認", text: $viewModel.confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                        .padding(.horizontal)
                    
                    if viewModel.confirmPasswordError != "" {
                        Text(viewModel.confirmPasswordError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 16)
                    }
                }
                .padding(.bottom, 10)

                // 新規登録ボタン
                Button(action: {
                    
                    Task.init {
                        await viewModel.checkUsernameAvailability()
                        try await viewModel.signup() // 新規登録処理
                    }
                }) {
                    HStack {
                        Text("登録する")
                            .font(.headline)
                            .padding()
                        Image(systemName: "checkmark.circle")
                    }.foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .red]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    
                }
                .padding()

                // ログイン画面への案内とボタン
                HStack {
                    Text("既にアカウントをお持ちですか？")
                    Button("ログイン") {
                        // ログイン画面に戻る
                        showSignupView = false
                    }
                }
                .padding()

                Spacer() // 下部にスペースを作るために追加
            }
            .padding()
            
            // Overlay for ProgressView
            if viewModel.isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    ProgressView("ユーザー登録中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

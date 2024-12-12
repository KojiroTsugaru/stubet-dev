//
//  ProfileEditPhotoPicker.swift
//  Stubet
//
//  Created by KJ on 12/11/24.
//

import SwiftUI
import PhotosUI

struct ProfileEditPhotoPicker: View {
    
    @ObservedObject var viewModel: ProfileEditViewModel
    @State var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            if let image = AccountManager.shared.currentUser?.iconImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            } else {
                // Placeholder or fallback
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            }
            PhotosPicker(
                selection: $selectedItem
            ) {
                // <ここにピッカーを呼び出すアクションボタンのビューを定義>
                Text("アイコン画像を選択")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        Color.orange
                    )
                    .cornerRadius(12)
            }
            .padding()
            // PhotosPickerItem -> Data -> UIImageに変換
            .onChange(of: selectedItem) { item in

                Task {
                    guard let data = try? await item?.loadTransferable(type: Data.self) else {
                        return
                    }
                    guard let uiImage = UIImage(data: data) else { return }
                    viewModel.iconImage = uiImage
                }
            }
            
        }
        .padding()
    }
}
//
//  AccountManager.swift
//  Stubet
//
//  Created by KJ on 11/10/24.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class AccountManager: NSObject, ObservableObject {
    
    static let shared = AccountManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    // ローカルの現在のユーザーを保持するためのPublishedプロパティ
    @Published var currentUser: User?
    @Published var handle: AuthStateDidChangeListenerHandle?

    private override init() {
        super.init()
        self.setUp()
    }
    
    // ユーザーがログインしているか確認するメソッド
    func setUp() {
        self.handle = Auth
            .auth()
            .addStateDidChangeListener({ [weak self] auth, user in
                if let self = self {
                    Task {
                        try await self.fetchCurrentUser()
                    }
                    DispatchQueue.main.async {
                        if user != nil {
                            print("User is logged in")
                        } else {
                            print("User is logged out")
                            self.currentUser = nil // Clear the current user if logged out
                        }
                    }
                }
            })
    }
    
    /// cleanup method to remove the listener if needed
    func removeAuthListener() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
            self.handle = nil
        }
    }
    
    /// Upload the profile image to Firebase Storage using async/await.
    func uploadIconImage(iconImage: UIImage?) async throws -> URL {
        guard let image = iconImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image."])
        }

        let imageName = UUID().uuidString
        let storageRef = storage.reference().child("profileImages/\(imageName).jpg")

        // Upload the image
        let metadata = try await storageRef.putDataAsync(imageData)

        // Retrieve the download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }
    
    func signUp(password: String, userName: String, displayName: String, iconImageUrl: URL?) async throws {
        
        // sign up with fake email address
        let email = "\(userName)@stubetapp.com"
        
        do {
            // Attempt to create a new user in Firebase Authentication
            let authResult = try await Auth.auth().createUser(
                withEmail: email,
                password: password
            )
            let user = authResult.user
            
            // Prepare user data for Firestore
            let userData: [String: Any] = [
                "userName": userName,
                "displayName": displayName,
                "iconUrl": iconImageUrl?.absoluteString ?? "" ,
                "email": email,
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date()),
            ]

            
            let userRef = db.collection("users").document(user.uid)
            try await userRef.setData(userData)
            
        } catch {
            print(error)
        }
    }
    
    // MARK: - Sign-In Method
    func signIn(userName: String, password: String) async throws {
        let email = "\(userName)@stubetapp.com" // Construct a placeholder email using username
        
        do {
            // Attempt to sign in with Firebase Authentication
            _ = try await Auth.auth().signIn(
                withEmail: email,
                password: password
            )
            
            Task.init {
                try await fetchCurrentUser() // Update the currentUser on successful sign-in
            }
            
        } catch let error as NSError {
            // Handle specific Firebase Authentication errors if needed
            switch AuthErrorCode(rawValue: error.code) {
            case .invalidEmail:
                throw SignInError.invalidEmail
            case .wrongPassword:
                throw SignInError.wrongPassword
            case .userNotFound:
                throw SignInError.userNotFound
            case .userDisabled:
                throw SignInError.userDisabled
            default:
                throw SignInError.unknownError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Sign-Out Method
    func signOut() async throws {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.currentUser = nil // Clear the current user on sign-out
            }
            
        } catch {
            throw SignInError.signOutFailed
        }
    }
    
    // userIDの取得
    public func getCurrentUserId() -> String? {
        return currentUser?.id
    }

    // convert Firestore data to User struct
    public func fetchCurrentUser() async throws {
        // Ensure that we have a current user
        guard let id = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "UserError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."]
            )
        }

        // Reference to the Firestore document
        let documentRef = Firestore.firestore().collection("users").document(id)
        
        do {
            // Fetch the document
            let documentSnapshot = try await documentRef.getDocument()
            
            // Check if the document exists and contains data
            guard let data = documentSnapshot.data() else {
                print("User document does not exist or has no data")
                return
            }
            
            // Update currentUser on the main thread
            DispatchQueue.main.async {
                self.currentUser = User(id: id, data: data)
            }
            
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
            throw error
        }
    }
    
    // fetch user by user id
    public func fetchUser(id: String) async throws -> User? {
        // Reference to the Firestore document
        let documentRef = Firestore.firestore().collection("users").document(id)
        
        do {
            // Fetch the document
            let documentSnapshot = try await documentRef.getDocument()
            
            // Check if the document exists and contains data
            guard let data = documentSnapshot.data() else {
                print("User document does not exist or has no data")
                return nil
            }
            
            return User(id: id, data: data)
            
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Custom error types for sign-in error handling
    enum SignInError: LocalizedError {
        case invalidEmail
        case wrongPassword
        case userNotFound
        case userDisabled
        case unknownError(String)
        case signOutFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidEmail:
                return "The email address format is invalid. Please enter a valid email."
            case .wrongPassword:
                return "The password you entered is incorrect. Please try again."
            case .userNotFound:
                return "No account found with the provided credentials."
            case .userDisabled:
                return "This account has been disabled. Please contact support."
            case .unknownError(let message):
                return message
            case .signOutFailed:
                return "Failed to sign out. Please try again."
            }
        }
    }
    
}

//
//  FriendManager.swift
//  Stubet
//
//  Created by KJ on 11/16/24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FriendManager: ObservableObject {
    static let shared = FriendManager()
    private let db = Firestore.firestore()
    private let currentUserId = Auth.auth().currentUser?.uid
    
    @Published var incomingRequests: [FriendRequest] = []
    @Published var friends: [Friend] = []
    
    // MARK: - Friend Management
    
    // Fetch the list of friends
    func fetchFriends() async throws {
        guard let currentUserId = currentUserId else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        let friendsRef = db.collection("users").document(currentUserId).collection("friends")
        
        do {
            // Fetch the documents asynchronously
            let snapshot = try await friendsRef.getDocuments()
            
            DispatchQueue.main.async {
                // Map the documents to Friend objects
                self.friends = snapshot.documents.compactMap { doc in
                    Friend(id: doc.documentID, data: doc.data())
                }
            }
        } catch {
            // Handle any errors that occur during the fetch
            print("Error fetching friends: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Add a friend by their user ID
    func addFriend(byUserId userId: String) async throws {
        guard let currentUserId = currentUserId else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        // Fetch the friend's data
        let friendDocument = try await db.collection("users").document(userId).getDocument()
        guard let friendData = friendDocument.data() else {
            throw NSError(domain: "AddFriendError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])
        }

        // Prepare friend data
        let friendDataForCurrentUser: [String: Any] = [
            "userName": friendData["userName"] ?? "",
            "displayName": friendData["displayName"] ?? "",
            "iconUrl": friendData["iconUrl"] ?? "",
            "addedAt": Timestamp(date: Date())
        ]

        // Add friend to the current user's friends subcollection
        try await db.collection("users").document(currentUserId).collection("friends").document(userId).setData(friendDataForCurrentUser)

        // Add mutual friendship
        try await addMutualFriend(currentUserId: currentUserId, friendId: userId, friendData: friendDataForCurrentUser)
    }

    private func addMutualFriend(currentUserId: String, friendId: String, friendData: [String: Any]) async throws {
        // Fetch the current user's data
        let currentUserDocument = try await db.collection("users").document(currentUserId).getDocument()
        
        guard let currentUserData = currentUserDocument.data() else {
            throw NSError(domain: "MutualFriendError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Current user data not found."])
        }

        // Prepare current user's data for the mutual relationship
        let currentUserFriendData: [String: Any] = [
            "userName": currentUserData["userName"] ?? "",
            "displayName": currentUserData["displayName"] ?? "",
            "addedAt": Timestamp(date: Date()),
            "icoUrl":currentUserData["iconUrl"] ?? "",
        ]

        // Add current user to the friend's friends subcollection
        try await db.collection("users").document(friendId).collection("friends").document(currentUserId).setData(currentUserFriendData)
    }

    // Remove a friend
    func removeFriend(friendId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = currentUserId else {
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])))
            return
        }

        // Delete friend from the current user's friends subcollection
        db.collection("users").document(currentUserId).collection("friends").document(friendId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Friend Requests

    // Send a friend request
    func sendFriendRequest(to userId: String) async throws {
        guard let currentUserId = currentUserId else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        // Fetch current user details
        let currentUserDocument = try await db.collection("users").document(currentUserId).getDocument()
        guard let currentUserData = currentUserDocument.data() else {
            throw NSError(domain: "FriendRequestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Current user data not found."])
        }

        // Prepare friend request data
        let requestData: [String: Any] = [
            "senderId": currentUserId,
            "senderName": currentUserData["userName"] ?? "",
            "senderDisplayName": currentUserData["displayName"] ?? "",
            "senderIconUrl": currentUserData["iconUrl"] ?? "",
            "status": "pending",
            "sentAt": Timestamp(date: Date())
        ]

        // Add the request to the target user's friendRequests subcollection
        try await db.collection("users").document(userId).collection("friendRequests").addDocument(data: requestData)
    }

    // Accept a friend request
    func acceptFriendRequest(requestId: String, senderId: String) async throws {
        guard let currentUserId = currentUserId else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        // Fetch the request data
        let requestRef = db.collection("users").document(currentUserId).collection("friendRequests").document(requestId)
        let requestDocument = try await requestRef.getDocument()
        guard let requestData = requestDocument.data(), requestData["status"] as? String == "pending" else {
            throw NSError(domain: "FriendRequestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Friend request not found or already handled."])
        }

        // Mark the request as accepted
        try await requestRef.updateData(["status": "accepted"])

        // Add the sender as a friend (mutual friendship handled in `addFriend`)
        try await addFriend(byUserId: senderId)
        
        // remove accepted request from incoming request
        await self.removeFriendRequest()
    }

    // Reject a friend request
    func rejectFriendRequest(requestId: String) async throws {
        guard let currentUserId = currentUserId else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        // Fetch the request reference and mark it as rejected
        let requestRef = db.collection("users").document(currentUserId).collection("friendRequests").document(requestId)
        try await requestRef.updateData(["status": "rejected"])
        
        // remove rejected request from incoming request
        await self.removeFriendRequest()
    }

    // Fetch all incoming friend requests
    func fetchFriendRequests() async throws {
        guard let currentUserId = currentUserId else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        let requestsSnapshot = try await db.collection("users").document(currentUserId).collection("friendRequests").whereField("status", isEqualTo: "pending").getDocuments()
        
        DispatchQueue.main.async {
            self.incomingRequests = requestsSnapshot.documents.compactMap { doc in
                FriendRequest(id: doc.documentID, data: doc.data())
            }
        }
    }
    
    // remove accepted & rejected friend request from incomingRequest
    @MainActor
    private func removeFriendRequest() {
        DispatchQueue.main.async {
            self.incomingRequests.removeAll { request in
                request.status == "accepted" || request.status == "rejected"
            }
        }
    }
    
    // call this function on sign out
    func emptyAllData() {
        self.incomingRequests = []
        self.friends = []
    }
}

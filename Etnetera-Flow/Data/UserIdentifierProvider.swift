import FirebaseAuth

protocol UserIdentifierProviding {
    func identifier() async throws -> String
}

final class UserIdentifierProvider: UserIdentifierProviding {
    func identifier() async throws -> String {
        if let user = Auth.auth().currentUser {
            return user.uid
        }

        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signInAnonymously { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result.user.uid)
                } else {
                    continuation.resume(
                        throwing: AuthenticationError.missingAuthenticatedUser
                    )
                }
            }
        }
    }
}

private enum AuthenticationError: LocalizedError {
    case missingAuthenticatedUser

    var errorDescription: String? {
        "Firebase did not return an authenticated user."
    }
}

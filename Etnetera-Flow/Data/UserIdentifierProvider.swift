import FirebaseAuth

protocol UserIdentifierProviding: Sendable {
    func identifier() async throws -> String
}

/// Resolves the anonymous Firebase user backing every remote document.
///
/// Sign-in is deduplicated: concurrent callers await the same task instead of
/// each starting their own `signInAnonymously`, which would create several
/// anonymous accounts and let a write land under a different uid than the one
/// the snapshot listener is watching.
actor UserIdentifierProvider: UserIdentifierProviding {
    private var signIn: Task<String, Error>?

    func identifier() async throws -> String {
        if let user = Auth.auth().currentUser {
            return user.uid
        }

        if let signIn {
            return try await signIn.value
        }

        let task = Task {
            try await Auth.auth().signInAnonymously().user.uid
        }
        signIn = task
        defer { signIn = nil }

        return try await task.value
    }
}

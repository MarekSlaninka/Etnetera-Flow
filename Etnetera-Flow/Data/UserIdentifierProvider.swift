import FirebaseAuth

protocol UserIdentifierProviding: Sendable {
    func identifier() async throws -> String
}

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

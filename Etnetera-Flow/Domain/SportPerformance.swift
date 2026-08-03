import Foundation

struct SportPerformance: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let location: String
    let duration: TimeInterval
    let storage: StorageType
    let createdAt: Date
}

enum StorageType: String, CaseIterable, Identifiable, Sendable {
    case local
    case remote

    var id: Self { self }
}

import Foundation

struct SportPerformance: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let location: String
    let duration: TimeInterval
    let storage: StorageType
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case duration
        case storage
        case createdAt
    }

    init(
        id: UUID,
        name: String,
        location: String,
        duration: TimeInterval,
        storage: StorageType,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.duration = duration
        self.storage = storage
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(String.self, forKey: .id)

        guard let id = UUID(uuidString: identifier) else {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: container,
                debugDescription: "Sport performance ID must be a UUID string."
            )
        }

        self.id = id
        name = try container.decode(String.self, forKey: .name)
        location = try container.decode(String.self, forKey: .location)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        storage = try container.decode(StorageType.self, forKey: .storage)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(location, forKey: .location)
        try container.encode(duration, forKey: .duration)
        try container.encode(storage, forKey: .storage)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

enum StorageType: String, CaseIterable, Identifiable, Codable {
    case local
    case remote

    var id: Self { self }
}

enum PerformanceFilter: CaseIterable, Identifiable {
    case all
    case local
    case remote
    
    var id: Self { self }
    
    func includes(_ performance: SportPerformance) -> Bool {
        switch self {
        case .all: true
        case .local: performance.storage == .local
        case .remote: performance.storage == .remote
        }
    }
}

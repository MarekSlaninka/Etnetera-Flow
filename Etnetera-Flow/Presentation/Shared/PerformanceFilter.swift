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

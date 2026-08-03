/// Which storage the list is currently showing.
///
/// This is a presentation concern rather than a domain rule — the repositories
/// know nothing about it — so it lives next to the views that offer the picker.
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

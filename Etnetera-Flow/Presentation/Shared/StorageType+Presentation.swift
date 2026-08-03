import SwiftUI

extension StorageType {
    var title: LocalizedStringResource {
        switch self {
        case .local: "storage.local"
        case .remote: "storage.firebase"
        }
    }

    var tint: Color {
        switch self {
        case .local: .green
        case .remote: .blue
        }
    }
}

extension PerformanceFilter {
    var title: LocalizedStringResource {
        switch self {
        case .all: "filter.all"
        case .local: "storage.local"
        case .remote: "filter.remote"
        }
    }
}

import Foundation
import MapKit

struct PlaceSuggestion: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String
}

struct ResolvedPlace: Equatable, Sendable {
    let name: String
    let coordinate: PerformanceCoordinate
}

@MainActor
@Observable
final class PlaceSearchService: NSObject, MKLocalSearchCompleterDelegate {
    private(set) var suggestions: [PlaceSuggestion] = []

    private let completer = MKLocalSearchCompleter()
    private var completions: [UUID: MKLocalSearchCompletion] = [:]
    private var debounce: Task<Void, Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    func search(_ query: String) {
        debounce?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 else {
            clear()
            return
        }

        debounce = Task {
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else { return }

            completer.queryFragment = trimmed
        }
    }

    func clear() {
        debounce?.cancel()
        debounce = nil
        suggestions = []
        completions = [:]
    }

    func resolve(_ suggestion: PlaceSuggestion) async -> ResolvedPlace? {
        guard let completion = completions[suggestion.id] else { return nil }

        let request = MKLocalSearch.Request(completion: completion)

        guard
            let response = try? await MKLocalSearch(request: request).start(),
            let item = response.mapItems.first
        else {
            return nil
        }

        let location = item.location.coordinate

        guard let coordinate = PerformanceCoordinate(
            latitude: location.latitude,
            longitude: location.longitude
        ) else {
            return nil
        }

        return ResolvedPlace(name: item.name ?? suggestion.title, coordinate: coordinate)
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            var resolved: [UUID: MKLocalSearchCompletion] = [:]

            suggestions = completer.results.prefix(8).map { completion in
                let identifier = UUID()
                resolved[identifier] = completion

                return PlaceSuggestion(
                    id: identifier,
                    title: completion.title,
                    subtitle: completion.subtitle
                )
            }

            completions = resolved
        }
    }

    nonisolated func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        MainActor.assumeIsolated {
            suggestions = []
            completions = [:]
        }
    }
}

import MapKit
import SwiftUI

struct LocationField: View {
    @Binding var location: String
    @Binding var coordinate: PerformanceCoordinate?

    @State private var search = PlaceSearchService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var resolvedName: String?
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        TextField(text: $location, prompt: Text("form.location")) {
            Text("form.location")
        }
        .textInputAutocapitalization(.words)
        .focused($isFieldFocused)
        .onChange(of: location) { _, newValue in
            guard newValue != resolvedName else { return }

            resolvedName = nil
            coordinate = nil
            search.search(newValue)
        }

        ForEach(search.suggestions) { suggestion in
            Button {
                select(suggestion)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.subheadline)
                    Text(suggestion.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }

        if let coordinate {
            pickedMap(for: coordinate)
        } else {
            Text("location.hint")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func pickedMap(for coordinate: PerformanceCoordinate) -> some View {
        MapReader { proxy in
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                Marker(location, coordinate: coordinate.mapCoordinate)
                    .tint(.mint)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture { point in
                guard let tapped = proxy.convert(point, from: .local) else { return }

                self.coordinate = PerformanceCoordinate(
                    latitude: tapped.latitude,
                    longitude: tapped.longitude
                )
            }
        }
        .listRowInsets(EdgeInsets())
        .onChange(of: coordinate) { _, newValue in
            cameraPosition = .region(newValue.region)
        }
        .onAppear {
            cameraPosition = .region(coordinate.region)
        }
    }

    private func select(_ suggestion: PlaceSuggestion) {
        Task {
            guard let place = await search.resolve(suggestion) else { return }

            isFieldFocused = false
            resolvedName = place.name
            location = place.name
            coordinate = place.coordinate
            cameraPosition = .region(place.coordinate.region)
            search.clear()
        }
    }
}

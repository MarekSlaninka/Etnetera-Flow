import MapKit
import SwiftUI

struct PerformanceMapView: View {
    let performances: [SportPerformance]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIdentifier: UUID?
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var mapped: [MappedPerformance] {
        performances.compactMap { performance in
            performance.coordinate.map {
                MappedPerformance(performance: performance, coordinate: $0)
            }
        }
    }

    private var selected: SportPerformance? {
        mapped.first { $0.id == selectedIdentifier }?.performance
    }

    var body: some View {
        NavigationStack {
            Group {
                if mapped.isEmpty {
                    ContentUnavailableView(
                        "map.empty.title",
                        systemImage: "mappin.slash",
                        description: Text("map.empty.description")
                    )
                } else {
                    Map(position: $cameraPosition, selection: $selectedIdentifier) {
                        ForEach(mapped) { item in
                            Marker(
                                item.performance.name,
                                systemImage: "figure.run",
                                coordinate: item.coordinate.mapCoordinate
                            )
                            .tint(item.performance.storage.tint)
                            .tag(item.id)
                        }
                    }
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }
                }
            }
            .navigationTitle(Text("map.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("action.close"))
                }
            }
            .sheet(item: Binding(
                get: { selected },
                set: { if $0 == nil { selectedIdentifier = nil } }
            )) { performance in
                PerformancePinDetail(performance: performance)
                    .presentationDetents([.height(220)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct MappedPerformance: Identifiable {
    let performance: SportPerformance
    let coordinate: PerformanceCoordinate

    var id: UUID { performance.id }
}

#Preview("Mapa výkonov") {
    PerformanceMapView(performances: [PreviewData.running, PreviewData.swimming])
}

#Preview("Bez súradníc") {
    PerformanceMapView(performances: [])
}

import MapKit
import SwiftUI

struct PerformanceMapView: View {
    let performances: [SportPerformance]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var selectedIdentifier: UUID?
    @State private var cameraPosition: MapCameraPosition

    init(performances: [SportPerformance], focused: SportPerformance? = nil) {
        self.performances = performances
        _selectedIdentifier = State(
            initialValue: PerformanceMapFocus.selection(focusing: focused)
        )
        _cameraPosition = State(
            initialValue: PerformanceMapFocus.position(focusing: focused)
        )
    }

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

    private var showsDetailBesideMap: Bool {
        verticalSizeClass == .compact
    }

    private var presentedInSheet: SportPerformance? {
        showsDetailBesideMap ? nil : selected
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
                    .overlay(alignment: .topTrailing) {
                        if showsDetailBesideMap, let selected {
                            detailCard(for: selected)
                        }
                    }
                    .animation(.snappy, value: selectedIdentifier)
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
                get: { presentedInSheet },
                set: { if $0 == nil { selectedIdentifier = nil } }
            )) { performance in
                PerformancePinDetail(performance: performance)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .presentationDetents([.height(220)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func detailCard(for performance: SportPerformance) -> some View {
        PerformancePinDetail(performance: performance)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topTrailing) {
                Button {
                    selectedIdentifier = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(10)
                .accessibilityLabel(Text("action.close"))
            }
            .padding()
            .transition(.move(edge: .trailing).combined(with: .opacity))
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

import SwiftUI

struct PerformanceRow: View {
    let performance: SportPerformance

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(performance.storage.tint)
                .frame(width: 12, height: 12)
                .accessibilityLabel(Text(performance.storage.title))

            VStack(alignment: .leading, spacing: 4) {
                Text(performance.name)
                    .font(.headline)
                Text(String(format: String(localized: "performance.detail"), performance.location, performance.duration.formattedDuration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Lokálny výkon") {
    List {
        PerformanceRow(performance: PreviewData.running)
    }
}

#Preview("Firebase výkon") {
    List {
        PerformanceRow(performance: PreviewData.swimming)
    }
}

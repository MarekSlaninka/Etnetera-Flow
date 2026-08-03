import SwiftUI

struct PerformancePinDetail: View {
    let performance: SportPerformance

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(performance.storage.tint)
                    .frame(width: 10, height: 10)

                Text(performance.name)
                    .font(.title3.weight(.semibold))

                Spacer()
            }

            LabeledContent {
                Text(performance.location)
            } label: {
                Label("form.location", systemImage: "mappin.and.ellipse")
            }

            LabeledContent {
                Text(performance.duration.formattedDuration)
            } label: {
                Label("form.duration", systemImage: "clock")
            }

            LabeledContent {
                Text(performance.createdAt, format: .dateTime.day().month().year())
            } label: {
                Label("detail.createdAt", systemImage: "calendar")
            }

            Spacer(minLength: 0)
        }
        .font(.subheadline)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Detail pinu") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PerformancePinDetail(performance: PreviewData.running)
                .presentationDetents([.height(220)])
        }
}

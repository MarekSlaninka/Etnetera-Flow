import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView("performance.loading")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(Text("performance.loading"))
    }
}

#Preview {
    LoadingView()
}

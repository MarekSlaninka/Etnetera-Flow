import SwiftUI
import FirebaseCore
import SwiftData

@main
struct Flow: App {
#if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif
    private let modelContainer: ModelContainer
    private let repository: SportPerformanceRepository

    init() {
        FirebaseApp.configure()

        do {
            modelContainer = try ModelContainer(for: SportPerformanceRecord.self)
        } catch {
            fatalError("Unable to create the local database: \(error)")
        }

        let localRepository = SwiftDataSportPerformanceRepository(
            modelContext: modelContainer.mainContext
        )
        let remoteRepository = FirestoreSportPerformanceRepository(
            userIdentifierProvider: UserIdentifierProvider()
        )
        repository = StorageRoutingSportPerformanceRepository(
            localRepository: localRepository,
            remoteRepository: remoteRepository
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository)
        }
        .modelContainer(modelContainer)
    }
}

import Testing
@testable import Etnetera_Flow

@MainActor
struct PerformanceFilterTests {
    @Test(arguments: [
        (PerformanceFilter.all, StorageType.local, true),
        (PerformanceFilter.all, StorageType.remote, true),
        (PerformanceFilter.local, StorageType.local, true),
        (PerformanceFilter.local, StorageType.remote, false),
        (PerformanceFilter.remote, StorageType.local, false),
        (PerformanceFilter.remote, StorageType.remote, true),
    ])
    func includesMatchingStorageOnly(
        filter: PerformanceFilter,
        storage: StorageType,
        expected: Bool
    ) {
        // Arrange
        let performance = SportPerformance.stub(storage: storage)

        // Act
        let isIncluded = filter.includes(performance)

        // Assert
        #expect(isIncluded == expected)
    }

    @Test(arguments: StorageType.allCases)
    func everyStorageTypeIsMatchedByExactlyTwoFilters(storage: StorageType) {
        // Arrange
        let performance = SportPerformance.stub(storage: storage)

        // Act
        let matching = PerformanceFilter.allCases.filter { $0.includes(performance) }

        // Assert
        #expect(matching.count == 2)
        #expect(matching.contains(.all))
    }
}

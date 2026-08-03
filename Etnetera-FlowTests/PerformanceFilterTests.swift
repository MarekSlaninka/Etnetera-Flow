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
        #expect(filter.includes(.stub(storage: storage)) == expected)
    }

    @Test
    func coversEveryStorageTypeAcrossItsCases() {
        for storage in StorageType.allCases {
            let matching = PerformanceFilter.allCases.filter {
                $0.includes(.stub(storage: storage))
            }

            #expect(matching.count == 2)
        }
    }
}

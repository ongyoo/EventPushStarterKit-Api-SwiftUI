//
//  DataLayerTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
@testable import DataLayer
import Testing

// Add tests per business area, e.g. DataLayerTests/<Area>/Remote<Area>RepositoryTests.swift
struct DataLayerTests {
    @Test func assemblyRegistersWithoutCrashing() {
        DataAssembly.register(in: Container())
    }
}

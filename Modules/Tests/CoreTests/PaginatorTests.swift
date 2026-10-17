//
//  PaginatorTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import Core
import Foundation
import Testing

@MainActor
struct PaginatorTests {
    private struct Row: Identifiable, Sendable, Equatable { let id: Int }
    private struct Failure: LocalizedError { var errorDescription: String? { "Boom" } }

    /// 25 rows served in pages; `failOn` pages throw.
    private final class Server: @unchecked Sendable {
        var all = (1...25).map(Row.init)
        var failOn: Set<Int> = []
        private(set) var requests: [PageRequest] = []

        func page(_ request: PageRequest) throws -> Page<Row> {
            requests.append(request)
            if failOn.contains(request.page) { throw Failure() }
            return .slice(all, request)
        }
    }

    private func make(_ server: Server, size: Int = 10) -> Paginator<Row> {
        Paginator(pageSize: size, prefetchDistance: 2) { try server.page($0) }
    }

    @Test func loadsPagesUntilTheEnd() async {
        let server = Server()
        let paginator = make(server)
        #expect(paginator.phase == .idle)

        await paginator.loadFirstPage()
        #expect(paginator.items.count == 10 && paginator.hasMore && paginator.phase == .loaded)
        await paginator.loadNextPage()
        await paginator.loadNextPage()
        #expect(paginator.items.count == 25)
        #expect(!paginator.hasMore)
        await paginator.loadNextPage()                       // nothing more: no request
        #expect(server.requests.map(\.page) == [1, 2, 3])
        #expect(server.requests[1].offset == 10)
    }

    @Test func loadMoreOnlyNearTheEnd() async {
        let server = Server()
        let paginator = make(server)
        await paginator.loadFirstPage()
        await paginator.loadMoreIfNeeded(currentItem: Row(id: 3))    // far from the end
        #expect(server.requests.count == 1)
        await paginator.loadMoreIfNeeded(currentItem: Row(id: 9))    // within prefetch distance
        #expect(server.requests.count == 2)
        await paginator.loadMoreIfNeeded(currentItem: Row(id: 999))  // unknown row: ignored
        await paginator.loadMoreIfNeeded(index: 0)
        #expect(server.requests.count == 2)
    }

    @Test func firstPageFailureThenRetry() async {
        let server = Server()
        server.failOn = [1]
        let paginator = make(server)
        await paginator.loadFirstPage()
        #expect(paginator.phase == .failed("Boom"))
        server.failOn = []
        await paginator.loadFirstPage()
        #expect(paginator.items.count == 10)
    }

    @Test func nextPageFailureKeepsItemsAndWaitsForRetry() async {
        let server = Server()
        server.failOn = [2]
        let paginator = make(server)
        await paginator.loadFirstPage()
        await paginator.loadNextPage()
        #expect(paginator.phase == .failedToLoadMore("Boom"))
        #expect(paginator.items.count == 10)

        await paginator.loadMoreIfNeeded(index: 9)   // no auto-retry loop after an error
        #expect(server.requests.count == 2)

        server.failOn = []
        await paginator.loadNextPage()               // explicit retry
        #expect(paginator.items.count == 20)
    }

    @Test func refreshReplacesAndDuplicatesAreDropped() async {
        let server = Server()
        let paginator = make(server)
        await paginator.loadFirstPage()
        server.all.insert(Row(id: 10), at: 10)       // server returns a duplicate on page 2
        await paginator.loadNextPage()
        #expect(Set(paginator.items.map(\.id)).count == paginator.items.count)

        server.all = [Row(id: 100)]
        await paginator.loadFirstPage()
        #expect(paginator.items == [Row(id: 100)])
        #expect(!paginator.hasMore)
    }

    @Test func cancellationDoesNotShowAnError() async {
        let paginator = Paginator<Row>(pageSize: 10) { _ in throw CancellationError() }
        await paginator.loadFirstPage()
        #expect(paginator.phase == .idle)
        #expect(!paginator.isLoading)
    }

    @Test func emptyPageStopsPaging() async {
        let paginator = Paginator<Row>(pageSize: 10) { _ in Page(items: [], hasMore: true) }
        await paginator.loadFirstPage()
        #expect(!paginator.hasMore)
    }
}

//
//  Paginator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation
import Observation

/// Which page to load. `page` starts at 1.
public struct PageRequest: Sendable, Equatable {
    public let page: Int
    public let size: Int

    public init(page: Int, size: Int) {
        self.page = page
        self.size = size
    }

    /// For offset-based APIs: `?offset=\(request.offset)&limit=\(request.size)`.
    public var offset: Int { (page - 1) * size }
}

/// One page of results returned by a repository.
public struct Page<Item: Sendable>: Sendable {
    public let items: [Item]
    /// `false` on the last page: the paginator stops asking.
    public let hasMore: Bool

    public init(items: [Item], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }

    /// Pages an in-memory array (local data, or an API without paging).
    public static func slice(_ all: [Item], _ request: PageRequest) -> Page<Item> {
        let start = min(request.offset, all.count)
        let end = min(start + request.size, all.count)
        return Page(items: Array(all[start..<end]), hasMore: end < all.count)
    }
}

/// Infinite scrolling ("load more") for any list, SwiftUI or UIKit.
///
///     let paginator = Paginator<Event>(pageSize: 20) { request in
///         try await repository.events(page: request)
///     }
///     await paginator.loadFirstPage()                        // first load / pull to refresh
///     await paginator.loadMoreIfNeeded(currentItem: event)   // in each row's onAppear
///
/// Built in: no duplicate requests, prefetch before the end, retry of the failed
/// page only, stale responses ignored after a refresh, duplicates (same id) dropped.
@MainActor
@Observable
public final class Paginator<Item: Identifiable & Sendable> {
    public enum Phase: Equatable, Sendable {
        case idle
        /// First page (or refresh) in flight.
        case loading
        /// Next page in flight: show a footer spinner.
        case loadingMore
        case loaded
        /// First page failed: show a full-screen error.
        case failed(String)
        /// A later page failed: keep the list, show a retry footer.
        case failedToLoadMore(String)
    }

    public private(set) var items: [Item] = []
    public private(set) var phase: Phase = .idle
    public private(set) var hasMore = true
    public let pageSize: Int
    /// Start loading the next page when this many rows are left.
    public let prefetchDistance: Int

    @ObservationIgnored private let fetch: (PageRequest) async throws -> Page<Item>
    @ObservationIgnored private var nextPage = 1
    @ObservationIgnored private var generation = 0

    public init(
        pageSize: Int = 20,
        prefetchDistance: Int = 3,
        fetch: @escaping (PageRequest) async throws -> Page<Item>
    ) {
        self.pageSize = pageSize
        self.prefetchDistance = prefetchDistance
        self.fetch = fetch
    }

    public var isLoading: Bool { phase == .loading || phase == .loadingMore }

    /// Loads page 1 and replaces the list (first load, pull to refresh, filter change).
    public func loadFirstPage() async {
        generation += 1
        nextPage = 1
        hasMore = true
        phase = .loading
        await load(generation: generation, replacing: true)
    }

    /// Loads the next page if there is one and nothing is in flight (also the retry action).
    public func loadNextPage() async {
        guard hasMore, !isLoading else { return }
        phase = .loadingMore
        await load(generation: generation, replacing: false)
    }

    /// Call from each row's `onAppear`: loads more near the end of the list.
    public func loadMoreIfNeeded(currentItem: Item) async {
        guard let index = items.lastIndex(where: { $0.id == currentItem.id }) else { return }
        await loadMoreIfNeeded(index: index)
    }

    /// UIKit version: `tableView(_:willDisplay:forRowAt:)` → `loadMoreIfNeeded(index: indexPath.row)`.
    public func loadMoreIfNeeded(index: Int) async {
        guard index >= items.count - prefetchDistance else { return }
        if case .failedToLoadMore = phase { return } // wait for an explicit retry
        await loadNextPage()
    }

    private func load(generation requested: Int, replacing: Bool) async {
        let request = PageRequest(page: nextPage, size: pageSize)
        do {
            let page = try await fetch(request)
            guard requested == generation else { return } // refreshed meanwhile
            if replacing {
                items = page.items
            } else {
                let known = Set(items.map(\.id))
                items += page.items.filter { !known.contains($0.id) }
            }
            hasMore = page.hasMore && !page.items.isEmpty
            nextPage += 1
            phase = .loaded
        } catch is CancellationError {
            guard requested == generation else { return }
            phase = items.isEmpty ? .idle : .loaded
        } catch {
            guard requested == generation else { return }
            phase = replacing && items.isEmpty
                ? .failed(error.localizedDescription)
                : .failedToLoadMore(error.localizedDescription)
        }
    }
}

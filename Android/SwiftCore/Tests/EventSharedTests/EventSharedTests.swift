//
//  EventSharedTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation
import Testing
@testable import EventShared

private let bangkok = 7 * 3_600

private func date(_ iso: String) -> Date {
    (try? Date(iso, strategy: .iso8601)) ?? .distantPast
}

private let json = Data("""
[
  {"id":"1","title":"King's Cup","description":"Football","price_starting_at":200,"organizer_name":"FA Thailand",
   "start_date":"2026-11-20T12:00:00Z","location":{"name":"Rajamangala Stadium","city":"Bangkok","latitude":0,"longitude":0},
   "thumbnail_url":"https://x/1.jpg","category":"sports","favorite_count":9700},
  {"id":"2","title":"Rock Night","price_starting_at":0,"start_date":"2026-11-02T13:00:00Z",
   "location":{"name":"Impact Arena","city":"Bangkok","latitude":0,"longitude":0},"category":"music","favorite_count":48306},
  {"id":"3","title":"Tokyo Game Show","price_starting_at":1500.4,"organizer_name":"CESA","start_date":"2027-01-10T01:00:00Z",
   "location":{"name":"Makuhari Messe","city":"Tokyo","latitude":0,"longitude":0},"category":"brand-new","favorite_count":950}
]
""".utf8)

struct EventCatalogTests {
    let catalog: EventCatalog

    init() throws {
        catalog = try EventCatalog(json: json)
    }

    @Test func decodesTheApiFormat() throws {
        #expect(catalog.events.count == 3)
        let first = try #require(catalog.events.first)
        #expect(first.venue == "Rajamangala Stadium")
        #expect(first.organizer == "FA Thailand")
        #expect(first.startsAt == date("2026-11-20T12:00:00Z"))
        #expect(catalog.events[1].summary.isEmpty)
        #expect(catalog.events[2].category == .other) // unknown value does not fail decoding
        #expect(throws: (any Error).self) { try EventCatalog(json: Data("{}".utf8)) }
    }

    @Test func searchMatchesEveryWordCaseInsensitively() {
        #expect(catalog.search(EventQuery(text: "bangkok")).map(\.id) == ["2", "1"])
        #expect(catalog.search(EventQuery(text: "ROCK  bangkok")).map(\.id) == ["2"])
        #expect(catalog.search(EventQuery(text: "cesa")).map(\.id) == ["3"])
        #expect(catalog.search(EventQuery(text: "nothing")).isEmpty)
        #expect(catalog.search(EventQuery(category: .sports)).map(\.id) == ["1"])
    }

    @Test func sortsByDatePopularityAndPrice() {
        #expect(catalog.search(EventQuery(sort: .soonest)).map(\.id) == ["2", "1", "3"])
        #expect(catalog.search(EventQuery(sort: .popular)).map(\.id) == ["2", "1", "3"])
        #expect(catalog.search(EventQuery(sort: .cheapest)).map(\.id) == ["2", "1", "3"])
    }

    @Test func snapshotGroupsByLocalMonthAndFormats() throws {
        let formatter = EventFormatter(language: .en, utcOffsetSeconds: bangkok)
        let snapshot = catalog.snapshot(for: EventQuery(), formatter: formatter, now: date("2026-11-01T00:00:00Z"))
        #expect(snapshot.total == 3)
        #expect(snapshot.matched == 3)
        #expect(snapshot.sections.map(\.title) == ["November 2026", "January 2027"])
        #expect(snapshot.categories.map(\.id) == ["all", "sports", "music", "other"])
        #expect(snapshot.sorts.count == EventSort.allCases.count)

        let row = try #require(snapshot.sections.first?.rows.last)
        #expect(row.place == "Rajamangala Stadium · Bangkok")
        #expect(row.date == "Fri, 20 Nov 2026 · 19:00")
        #expect(row.countdown == "In 19 days")
        #expect(row.price == "From ฿200")
        #expect(row.favorites == "9.7K")

        let popular = catalog.snapshot(for: EventQuery(sort: .popular), formatter: formatter, now: .now)
        #expect(popular.sections.map(\.title) == ["Most popular"])
        #expect(catalog.snapshot(for: EventQuery(text: "zzz", sort: .cheapest), formatter: formatter, now: .now).sections.isEmpty)

        // Round-trips as JSON (what Kotlin receives).
        let data = try JSONEncoder().encode(snapshot)
        #expect(try JSONDecoder().decode(CatalogSnapshot.self, from: data) == snapshot)
    }
}

struct EventFormatterTests {
    let en = EventFormatter(language: .en, utcOffsetSeconds: bangkok)
    let th = EventFormatter(language: .th, utcOffsetSeconds: bangkok)

    @Test func formatsDatesInBothLanguages() {
        let event = date("2026-11-20T12:00:00Z")
        #expect(en.dateLine(event) == "Fri, 20 Nov 2026 · 19:00")
        #expect(th.dateLine(event) == "ศ. 20 พ.ย. 2569 · 19:00")
        #expect(th.monthTitle(year: 2026, month: 12) == "ธันวาคม 2569")
        // The offset moves the calendar day.
        #expect(EventFormatter(language: .en, utcOffsetSeconds: 0).dateLine(date("2026-11-20T23:30:00Z")) == "Fri, 20 Nov 2026 · 23:30")
        #expect(en.dateLine(date("2026-11-20T23:30:00Z")) == "Sat, 21 Nov 2026 · 06:30")
    }

    @Test func formatsPricesAndCounts() {
        #expect(en.price(0) == "Free")
        #expect(th.price(0) == "ฟรี")
        #expect(en.price(1_500.4) == "From ฿1,500")
        #expect(th.price(1_234_567) == "เริ่มต้น ฿1,234,567")
        #expect(en.compactCount(950) == "950")
        #expect(en.compactCount(9_700) == "9.7K")
        #expect(en.compactCount(10_000) == "10K")
        #expect(en.compactCount(1_250_000) == "1.3M")
    }

    @Test func countsDownInCalendarDays() {
        let now = date("2026-11-01T10:00:00Z") // 17:00 in Bangkok
        #expect(en.countdown(to: date("2026-11-01T12:00:00Z"), now: now) == "Today")
        #expect(en.countdown(to: date("2026-11-01T08:00:00Z"), now: now) == "Started")
        #expect(en.countdown(to: date("2026-11-01T18:00:00Z"), now: now) == "Tomorrow") // 01:00 next day locally
        #expect(th.countdown(to: date("2026-11-11T10:00:00Z"), now: now) == "อีก 10 วัน")
        #expect(th.countdown(to: date("2026-10-01T10:00:00Z"), now: now) == "จบแล้ว")
    }

    @Test func civilDateMatchesKnownDates() {
        let epoch = CivilDate(Date(timeIntervalSince1970: 0), utcOffsetSeconds: 0)
        #expect(fields(epoch) == [1970, 1, 1, 4, 0, 0])
        let leap = CivilDate(date("2028-02-29T00:00:00Z"), utcOffsetSeconds: 0)
        #expect(fields(leap) == [2028, 2, 29, 2, 0, 0])
        let before = CivilDate(Date(timeIntervalSince1970: -1), utcOffsetSeconds: 0)
        #expect(fields(before) == [1969, 12, 31, 3, 23, 59])
    }

    private func fields(_ d: CivilDate) -> [Int] {
        [d.year, d.month, d.day, d.weekday, d.hour, d.minute]
    }

    @Test func titlesExistForEveryCase() {
        for language in AppLanguage.allCases {
            let formatter = EventFormatter(language: language, utcOffsetSeconds: 0)
            #expect(!formatter.title(of: nil).isEmpty)
            for category in EventCategory.allCases { #expect(!formatter.title(of: category).isEmpty) }
            for sort in EventSort.allCases { #expect(!formatter.title(of: sort).isEmpty) }
        }
        #expect(SwiftRuntime.summary.hasPrefix("Swift "))
    }
}

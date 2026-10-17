//
//  EventFormatter.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//


#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Languages the shared texts support.
public enum AppLanguage: String, Sendable, Codable, CaseIterable {
    case en, th
}

/// Turns events into display text, the same way on every platform.
///
///     let formatter = EventFormatter(language: .th, utcOffsetSeconds: 7 * 3600)
///     formatter.dateLine(event.startsAt)   // "ศ. 20 พ.ย. 2569 · 19:00"
public struct EventFormatter: Sendable {
    public let language: AppLanguage
    public let utcOffsetSeconds: Int

    public init(language: AppLanguage, utcOffsetSeconds: Int) {
        self.language = language
        self.utcOffsetSeconds = utcOffsetSeconds
    }

    /// "Fri, 20 Nov 2026 · 19:00" / "ศ. 20 พ.ย. 2569 · 19:00"
    public func dateLine(_ date: Date) -> String {
        let c = CivilDate(date, utcOffsetSeconds: utcOffsetSeconds)
        let time = "\(Self.twoDigits(c.hour)):\(Self.twoDigits(c.minute))"
        switch language {
        case .en: return "\(Self.enWeekdays[c.weekday]), \(c.day) \(Self.enMonthsShort[c.month - 1]) \(c.year) · \(time)"
        case .th: return "\(Self.thWeekdays[c.weekday]) \(c.day) \(Self.thMonthsShort[c.month - 1]) \(c.year + 543) · \(time)"
        }
    }

    /// Section title: "November 2026" / "พฤศจิกายน 2569"
    public func monthTitle(year: Int, month: Int) -> String {
        switch language {
        case .en: "\(Self.enMonths[month - 1]) \(year)"
        case .th: "\(Self.thMonths[month - 1]) \(year + 543)"
        }
    }

    /// "Free" or "From ฿1,200"
    public func price(_ value: Double) -> String {
        if value <= 0 { return language == .en ? "Free" : "ฟรี" }
        let amount = "฿" + Self.grouped(Int(value.rounded()))
        return language == .en ? "From \(amount)" : "เริ่มต้น \(amount)"
    }

    /// 950 -> "950", 9_700 -> "9.7K", 1_250_000 -> "1.3M"
    public func compactCount(_ value: Int) -> String {
        switch value {
        case ..<1_000: "\(value)"
        case ..<1_000_000: Self.oneDecimal(Double(value) / 1_000) + "K"
        default: Self.oneDecimal(Double(value) / 1_000_000) + "M"
        }
    }

    /// "Today", "Tomorrow", "In 12 days", "Ended" (calendar days, local time).
    public func countdown(to date: Date, now: Date) -> String {
        let days = CivilDate(date, utcOffsetSeconds: utcOffsetSeconds).dayNumber
            - CivilDate(now, utcOffsetSeconds: utcOffsetSeconds).dayNumber
        switch (days, language) {
        case (..<0, .en): return "Ended"
        case (..<0, .th): return "จบแล้ว"
        case (0, .en): return date < now ? "Started" : "Today"
        case (0, .th): return date < now ? "เริ่มแล้ว" : "วันนี้"
        case (1, .en): return "Tomorrow"
        case (1, .th): return "พรุ่งนี้"
        case (_, .en): return "In \(days) days"
        case (_, .th): return "อีก \(days) วัน"
        }
    }

    public func title(of category: EventCategory?) -> String {
        switch (category, language) {
        case (nil, .en): "All"
        case (nil, .th): "ทั้งหมด"
        case (.sports?, .en): "Sports"
        case (.sports?, .th): "กีฬา"
        case (.entertainment?, .en): "Entertainment"
        case (.entertainment?, .th): "บันเทิง"
        case (.education?, .en): "Education"
        case (.education?, .th): "การศึกษา"
        case (.music?, .en): "Music"
        case (.music?, .th): "ดนตรี"
        case (.community?, .en): "Community"
        case (.community?, .th): "ชุมชน"
        case (.other?, .en): "Other"
        case (.other?, .th): "อื่นๆ"
        }
    }

    public func title(of sort: EventSort) -> String {
        switch (sort, language) {
        case (.soonest, .en): "Soonest"
        case (.soonest, .th): "ใกล้ที่สุด"
        case (.popular, .en): "Most popular"
        case (.popular, .th): "ยอดนิยม"
        case (.cheapest, .en): "Lowest price"
        case (.cheapest, .th): "ราคาต่ำสุด"
        }
    }

    // MARK: - Helpers

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }

    private static func grouped(_ value: Int) -> String {
        let digits = Array(String(abs(value)))
        var result = ""
        for (index, digit) in digits.enumerated() {
            if index > 0, (digits.count - index) % 3 == 0 { result.append(",") }
            result.append(digit)
        }
        return value < 0 ? "-" + result : result
    }

    private static func oneDecimal(_ value: Double) -> String {
        let tenths = Int((value * 10).rounded())
        return tenths % 10 == 0 ? "\(tenths / 10)" : "\(tenths / 10).\(tenths % 10)"
    }

    private static let enWeekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private static let thWeekdays = ["อา.", "จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส."]
    private static let enMonthsShort = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    private static let enMonths = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]
    private static let thMonthsShort = ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."]
    private static let thMonths = [
        "มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน",
        "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม",
    ]
}

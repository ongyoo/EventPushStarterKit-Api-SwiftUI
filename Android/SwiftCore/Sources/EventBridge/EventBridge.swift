//
//  EventBridge.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

// JNI entry points for `com.eventpush.android.SwiftBridge` (Kotlin).
//
// Rules of the bridge:
// - Data crosses as UTF-8 JSON in byte arrays: one simple, debuggable format.
// - A catalog lives in Swift; Kotlin holds an opaque handle (Long) and must
//   call `destroy` exactly once (SwiftEventCatalog.close() does it).
// - Swift never throws across JNI: errors become a Java IllegalStateException.
// - EventCatalog is immutable, so calls are safe from any Kotlin thread.

#if os(Android)
import CJNI
import EventShared
import FoundationEssentials

/// Reference box so the catalog can be handed to Kotlin as a pointer.
private final class CatalogBox: Sendable {
    let catalog: EventCatalog

    init(_ catalog: EventCatalog) {
        self.catalog = catalog
    }
}

/// What Kotlin sends with each query.
private struct QueryRequest: Decodable {
    let query: EventQuery
    let language: AppLanguage
    let utcOffsetSeconds: Int
    let nowMillis: Int64
}

// MARK: - Exports

/// `external fun runtimeInfo(): ByteArray`
@_cdecl("Java_com_eventpush_android_SwiftBridge_runtimeInfo")
public func runtimeInfo(_ env: UnsafeMutablePointer<JNIEnv?>, _ this: jobject?) -> jbyteArray? {
    bytes(env, Array(SwiftRuntime.summary.utf8))
}

/// `external fun create(json: ByteArray): Long` — returns a handle, throws on invalid JSON.
@_cdecl("Java_com_eventpush_android_SwiftBridge_create")
public func create(_ env: UnsafeMutablePointer<JNIEnv?>, _ this: jobject?, _ json: jbyteArray?) -> jlong {
    do {
        let catalog = try EventCatalog(json: Data(read(env, json)))
        let pointer = Unmanaged.passRetained(CatalogBox(catalog)).toOpaque()
        return jlong(Int(bitPattern: pointer))
    } catch {
        cjni_throw_illegal_state(env, "Invalid events JSON: \(error)")
        return 0
    }
}

/// `external fun query(handle: Long, request: ByteArray): ByteArray` — CatalogSnapshot as JSON.
@_cdecl("Java_com_eventpush_android_SwiftBridge_query")
public func query(_ env: UnsafeMutablePointer<JNIEnv?>, _ this: jobject?, _ handle: jlong, _ request: jbyteArray?) -> jbyteArray? {
    guard let box = box(from: handle) else {
        cjni_throw_illegal_state(env, "Catalog handle is closed or invalid")
        return nil
    }
    do {
        let request = try JSONDecoder().decode(QueryRequest.self, from: Data(read(env, request)))
        let formatter = EventFormatter(language: request.language, utcOffsetSeconds: request.utcOffsetSeconds)
        let now = Date(timeIntervalSince1970: Double(request.nowMillis) / 1_000)
        let snapshot = box.catalog.snapshot(for: request.query, formatter: formatter, now: now)
        return bytes(env, Array(try JSONEncoder().encode(snapshot)))
    } catch {
        cjni_throw_illegal_state(env, "Query failed: \(error)")
        return nil
    }
}

/// `external fun destroy(handle: Long)` — releases the Swift catalog.
@_cdecl("Java_com_eventpush_android_SwiftBridge_destroy")
public func destroy(_ env: UnsafeMutablePointer<JNIEnv?>, _ this: jobject?, _ handle: jlong) {
    guard let pointer = UnsafeRawPointer(bitPattern: Int(handle)) else { return }
    Unmanaged<CatalogBox>.fromOpaque(pointer).release()
}

// MARK: - Helpers

private func box(from handle: jlong) -> CatalogBox? {
    guard let pointer = UnsafeRawPointer(bitPattern: Int(handle)) else { return nil }
    return Unmanaged<CatalogBox>.fromOpaque(pointer).takeUnretainedValue()
}

private func read(_ env: UnsafeMutablePointer<JNIEnv?>, _ array: jbyteArray?) -> [UInt8] {
    let count = cjni_byte_array_length(env, array)
    var buffer = [UInt8](repeating: 0, count: Int(count))
    buffer.withUnsafeMutableBytes { cjni_byte_array_copy(env, array, count, $0.baseAddress) }
    return buffer
}

private func bytes(_ env: UnsafeMutablePointer<JNIEnv?>, _ value: [UInt8]) -> jbyteArray? {
    value.withUnsafeBytes { cjni_new_byte_array(env, $0.baseAddress, jsize(value.count)) }
}
#endif

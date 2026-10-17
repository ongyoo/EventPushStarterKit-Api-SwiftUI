//
//  SwiftBridge.kt
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

package com.eventpush.android

import org.json.JSONArray
import org.json.JSONObject

/**
 * Raw JNI functions implemented in Swift (SwiftCore/Sources/EventBridge).
 * Use [SwiftEventCatalog] instead of calling these directly.
 */
internal object SwiftBridge {
    init {
        System.loadLibrary("EventBridge") // libEventBridge.so, built by scripts/build-swift.sh
    }

    external fun runtimeInfo(): ByteArray
    external fun create(json: ByteArray): Long
    external fun query(handle: Long, request: ByteArray): ByteArray
    external fun destroy(handle: Long)

    /** "Swift 6.4 · Android · arm64", computed by Swift. */
    val runtime: String by lazy { runtimeInfo().decodeToString() }
}

/**
 * Event business logic running in Swift. Thread-safe: calls are serialized with
 * [close], so the Swift object can never be freed while a query is running.
 *
 * Owns native memory: call [close] when done (the ViewModel does it in onCleared).
 *
 *     SwiftEventCatalog(json).use { catalog -> catalog.query(request) }
 */
class SwiftEventCatalog(json: ByteArray) : AutoCloseable {
    private var handle: Long = SwiftBridge.create(json)

    /** Duration of the last native call (search + sort + group + format + encode), in microseconds. */
    @Volatile var lastNativeMicros: Long = 0
        private set

    fun query(request: QueryRequest): Snapshot {
        val input = request.toJson().toByteArray()
        val bytes = synchronized(this) {
            check(handle != 0L) { "SwiftEventCatalog is closed" }
            val start = System.nanoTime()
            SwiftBridge.query(handle, input).also { lastNativeMicros = (System.nanoTime() - start) / 1_000 }
        }
        return Snapshot.parse(JSONObject(bytes.decodeToString()))
    }

    @Synchronized
    override fun close() {
        if (handle != 0L) {
            SwiftBridge.destroy(handle)
            handle = 0L
        }
    }
}

/** Mirrors Swift `EventQuery` + formatting context. */
data class QueryRequest(
    val text: String = "",
    val category: String? = null,
    val sort: String = "soonest",
    val language: String = "en",
    val utcOffsetSeconds: Int = 0,
    val nowMillis: Long = System.currentTimeMillis(),
) {
    fun toJson(): String = JSONObject()
        .put("query", JSONObject().put("text", text).put("sort", sort).apply { category?.let { put("category", it) } })
        .put("language", language)
        .put("utcOffsetSeconds", utcOffsetSeconds)
        .put("nowMillis", nowMillis)
        .toString()
}

/** Mirrors Swift `CatalogSnapshot`: display-ready, nothing to format in Kotlin. */
data class Snapshot(
    val total: Int,
    val matched: Int,
    val categories: List<Chip>,
    val sorts: List<Chip>,
    val sections: List<Section>,
) {
    data class Chip(val id: String, val title: String, val count: Int)
    data class Section(val id: String, val title: String, val rows: List<Row>)
    data class Row(
        val id: String,
        val title: String,
        val place: String,
        val date: String,
        val countdown: String,
        val price: String,
        val favorites: String,
        val category: String,
        val categoryTitle: String,
        val organizer: String,
        val summary: String,
        val imageURL: String?,
    )

    companion object {
        fun parse(json: JSONObject) = Snapshot(
            total = json.getInt("total"),
            matched = json.getInt("matched"),
            categories = json.getJSONArray("categories").map(::chip),
            sorts = json.getJSONArray("sorts").map(::chip),
            sections = json.getJSONArray("sections").map { section ->
                Section(section.getString("id"), section.getString("title"), section.getJSONArray("rows").map(::row))
            },
        )

        private fun chip(json: JSONObject) = Chip(json.getString("id"), json.getString("title"), json.getInt("count"))

        private fun row(json: JSONObject) = Row(
            id = json.getString("id"),
            title = json.getString("title"),
            place = json.getString("place"),
            date = json.getString("date"),
            countdown = json.getString("countdown"),
            price = json.getString("price"),
            favorites = json.getString("favorites"),
            category = json.getString("category"),
            categoryTitle = json.getString("categoryTitle"),
            organizer = json.getString("organizer"),
            summary = json.getString("summary"),
            imageURL = json.optString("imageURL").ifEmpty { null },
        )

        private fun <T> JSONArray.map(transform: (JSONObject) -> T): List<T> =
            (0 until length()).map { transform(getJSONObject(it)) }
    }
}

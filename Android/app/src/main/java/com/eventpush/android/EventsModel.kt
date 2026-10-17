//
//  EventsModel.kt
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

package com.eventpush.android

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.TimeZone

/**
 * Screen state. Kotlin only keeps UI state; every rule (search, sort,
 * grouping, formatting, Thai/English texts) runs in Swift.
 */
class EventsModel(application: Application) : AndroidViewModel(application) {
    private val catalog = SwiftEventCatalog(application.assets.open("events.json").use { it.readBytes() })
    private var queryJob: Job? = null

    val runtime: String = SwiftBridge.runtime
    var text by mutableStateOf(""); private set
    var category by mutableStateOf<String?>(null); private set
    var sort by mutableStateOf("soonest"); private set
    var language by mutableStateOf("en"); private set
    var snapshot by mutableStateOf<Snapshot?>(null); private set
    /** Time spent in Swift for the last query (JNI call included), in microseconds. */
    var lastQueryMicros by mutableStateOf(0L); private set

    init {
        refresh()
    }

    fun search(value: String) { text = value; refresh() }
    fun select(categoryId: String?) { category = categoryId; refresh() }
    fun sortBy(sortId: String) { sort = sortId; refresh() }
    fun toggleLanguage() { language = if (language == "en") "th" else "en"; refresh() }

    private fun refresh() {
        val request = QueryRequest(
            text = text,
            category = category,
            sort = sort,
            language = language,
            utcOffsetSeconds = TimeZone.getDefault().getOffset(System.currentTimeMillis()) / 1000,
        )
        queryJob?.cancel() // only the latest keystroke matters
        queryJob = viewModelScope.launch {
            val (result, micros) = withContext(Dispatchers.Default) {
                catalog.query(request) to catalog.lastNativeMicros
            }
            snapshot = result
            lastQueryMicros = micros
        }
    }

    override fun onCleared() {
        queryJob?.cancel()
        catalog.close() // frees the Swift object
    }
}

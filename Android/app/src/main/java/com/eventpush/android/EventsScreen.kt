//
//  EventsScreen.kt
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

package com.eventpush.android

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private val Brand = Color(0xFF7952FC)
private val BrandDark = Color(0xFF4A2FD0)
private val Page = Color(0xFFF4F3F8)

/** Kotlin owns only these UI labels; every event text comes from Swift. */
private fun label(language: String, en: String, th: String) = if (language == "th") th else en

@Composable
fun EventsScreen(model: EventsModel) {
    MaterialTheme(colorScheme = lightColorScheme(primary = Brand, secondaryContainer = Brand.copy(alpha = 0.15f))) {
        var selected by remember { mutableStateOf<Snapshot.Row?>(null) }
        Surface(Modifier.fillMaxSize(), color = Page) {
            EventList(model, onSelect = { selected = it })
        }
        selected?.let { row -> EventSheet(row, model.language) { selected = null } }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun EventList(model: EventsModel, onSelect: (Snapshot.Row) -> Unit) {
    val snapshot = model.snapshot
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item(key = "header") { Header(model) }
        item(key = "search") {
            OutlinedTextField(
                value = model.text,
                onValueChange = model::search,
                placeholder = { Text(label(model.language, "Search events, cities, venues", "ค้นหางาน เมือง สถานที่")) },
                singleLine = true,
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            )
        }
        if (snapshot != null) {
            item(key = "categories") {
                ChipRow(snapshot.categories, selectedId = model.category ?: "all") { id ->
                    model.select(id.takeUnless { it == "all" })
                }
            }
            item(key = "sorts") { ChipRow(snapshot.sorts, selectedId = model.sort, showCount = false, onSelect = model::sortBy) }
            item(key = "stats") {
                Text(
                    label(model.language, "${snapshot.matched} of ${snapshot.total} events", "${snapshot.matched} จาก ${snapshot.total} งาน") +
                        " · Swift ${"%.2f".format(model.lastQueryMicros / 1000.0)} ms",
                    style = MaterialTheme.typography.labelMedium,
                    color = Color.Gray,
                    modifier = Modifier.padding(horizontal = 16.dp),
                )
            }
            if (snapshot.sections.isEmpty()) {
                item(key = "empty") {
                    Text(
                        label(model.language, "No events match your search.", "ไม่พบงานที่ค้นหา"),
                        modifier = Modifier.fillMaxWidth().padding(32.dp),
                        color = Color.Gray,
                    )
                }
            }
            snapshot.sections.forEach { section ->
                stickyHeader(key = section.id) {
                    Text(
                        section.title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.fillMaxWidth().background(Page).padding(horizontal = 16.dp, vertical = 8.dp),
                    )
                }
                items(section.rows, key = { "${section.id}-${it.id}" }) { row ->
                    EventCard(row, Modifier.animateItem()) { onSelect(row) }
                }
            }
        }
    }
}

@Composable
private fun Header(model: EventsModel) {
    Column(
        Modifier
            .fillMaxWidth()
            .background(Brush.linearGradient(listOf(Brand, BrandDark)), RoundedCornerShape(bottomStart = 28.dp, bottomEnd = 28.dp))
            .statusBarsPadding()
            .padding(20.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text("EventPush", color = Color.White, fontSize = 28.sp, fontWeight = FontWeight.Bold)
                Text(
                    label(model.language, "Business logic written in Swift", "Business logic เขียนด้วย Swift"),
                    color = Color.White.copy(alpha = 0.85f),
                )
            }
            TextButton(onClick = model::toggleLanguage) {
                Text(if (model.language == "en") "ไทย" else "EN", color = Color.White, fontWeight = FontWeight.Bold)
            }
        }
        Spacer(Modifier.height(12.dp))
        Text(
            "⚡ ${model.runtime}",
            color = Color.White,
            style = MaterialTheme.typography.labelLarge,
            modifier = Modifier.background(Color.White.copy(alpha = 0.18f), CircleShape).padding(horizontal = 12.dp, vertical = 6.dp),
        )
    }
}

@Composable
private fun ChipRow(chips: List<Snapshot.Chip>, selectedId: String, showCount: Boolean = true, onSelect: (String) -> Unit) {
    LazyRow(contentPadding = PaddingValues(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        items(chips, key = { it.id }) { chip ->
            FilterChip(
                selected = chip.id == selectedId,
                onClick = { onSelect(chip.id) },
                label = { Text(if (showCount) "${chip.title} ${chip.count}" else chip.title) },
                colors = FilterChipDefaults.filterChipColors(selectedContainerColor = Brand, selectedLabelColor = Color.White),
            )
        }
    }
}

@Composable
private fun EventCard(row: Snapshot.Row, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Card(
        modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp).clip(RoundedCornerShape(20.dp)).clickable(onClick = onClick),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
    ) {
        Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(56.dp).background(Brand.copy(alpha = 0.12f), RoundedCornerShape(14.dp)),
                contentAlignment = Alignment.Center,
            ) {
                Text(categoryEmoji(row.category), fontSize = 26.sp)
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(row.title, fontWeight = FontWeight.SemiBold, maxLines = 2, overflow = TextOverflow.Ellipsis)
                Text(row.date, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                Text(row.place, style = MaterialTheme.typography.bodySmall, color = Color.Gray, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Spacer(Modifier.height(6.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Pill(row.countdown)
                    Text(row.price, style = MaterialTheme.typography.labelMedium, color = BrandDark, fontWeight = FontWeight.Bold)
                    Text("♥ ${row.favorites}", style = MaterialTheme.typography.labelMedium, color = Color.Gray)
                }
            }
        }
    }
}

@Composable
private fun Pill(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.labelSmall,
        color = Brand,
        modifier = Modifier.background(Brand.copy(alpha = 0.12f), CircleShape).padding(horizontal = 8.dp, vertical = 3.dp),
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EventSheet(row: Snapshot.Row, language: String, onDismiss: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = Color.White) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 40.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("${categoryEmoji(row.category)}  ${row.categoryTitle}", color = Brand, fontWeight = FontWeight.SemiBold)
            Text(row.title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            Text(row.date)
            Text(row.place, color = Color.Gray)
            if (row.organizer.isNotEmpty()) Text(label(language, "by ", "โดย ") + row.organizer, color = Color.Gray)
            if (row.summary.isNotEmpty()) Text(row.summary)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                Pill(row.countdown)
                Text(row.price, fontWeight = FontWeight.Bold, color = BrandDark)
                Text("♥ ${row.favorites}", color = Color.Gray)
            }
        }
    }
}

private fun categoryEmoji(category: String) = when (category) {
    "sports" -> "🏟️"
    "music" -> "🎵"
    "entertainment" -> "🎬"
    "education" -> "📚"
    "community" -> "🤝"
    else -> "✨"
}

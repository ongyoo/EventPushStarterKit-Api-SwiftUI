//
//  MainActivity.kt
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

package com.eventpush.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels

class MainActivity : ComponentActivity() {
    private val model: EventsModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { EventsScreen(model) }
    }
}

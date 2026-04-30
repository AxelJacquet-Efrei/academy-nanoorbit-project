package com.efrei.nanoorbit.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.util.concurrent.TimeUnit

@Composable
fun OfflineBanner(cacheAgeMillis: Long?, modifier: Modifier = Modifier) {
    val ageText = cacheAgeMillis?.let { millis ->
        val minutes = TimeUnit.MILLISECONDS.toMinutes(millis).coerceAtLeast(0)
        if (minutes < 1) "Mis a jour a l'instant" else "Mis a jour il y a $minutes min"
    } ?: "Age du cache inconnu"

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.errorContainer)
            .padding(12.dp)
    ) {
        Text("Mode hors-ligne", style = MaterialTheme.typography.titleSmall)
        Text(ageText, style = MaterialTheme.typography.bodySmall)
    }
}

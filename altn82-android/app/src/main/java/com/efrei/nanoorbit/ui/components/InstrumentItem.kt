package com.efrei.nanoorbit.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.efrei.nanoorbit.data.models.Instrument

@Composable
fun InstrumentItem(
    instrument: Instrument,
    etatFonctionnement: String,
    modifier: Modifier = Modifier
) {
    val indicatorColor = if (etatFonctionnement.equals("OK", ignoreCase = true)) {
        Color(0xFF4CAF50)
    } else {
        Color(0xFFF44336)
    }

    Card(modifier = modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(modifier = Modifier.size(12.dp), shape = CircleShape, color = indicatorColor) {}
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(
                    text = "${instrument.typeInstrument} - ${instrument.modele}",
                    style = MaterialTheme.typography.titleMedium
                )
                val resolutionText = instrument.resolution?.let { "$it m" } ?: "N/A"
                Text(
                    text = "Resolution: $resolutionText",
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = "Etat: $etatFonctionnement",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

@Preview
@Composable
fun InstrumentItemPreview() {
    InstrumentItem(
        instrument = Instrument("INS-CAM-01", "Camera optique", "PlanetScope-Mini", 3.0, 2.5),
        etatFonctionnement = "OK"
    )
}

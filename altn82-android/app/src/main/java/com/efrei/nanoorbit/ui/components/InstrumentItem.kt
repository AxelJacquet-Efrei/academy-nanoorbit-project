package com.efrei.nanoorbit.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.tooling.preview.Preview
import com.efrei.nanoorbit.data.models.Instrument

@Composable
fun InstrumentItem(
    instrument: Instrument,
    etatFonctionnement: String,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            val indicatorColor = if (etatFonctionnement == "OK") Color(0xFF4CAF50) else Color(0xFFF44336)
            
            Surface(
                modifier = Modifier.size(12.dp),
                shape = CircleShape,
                color = indicatorColor
            ) {}
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column {
                Text(
                    text = "${instrument.typeInstrument} ()",
                    style = MaterialTheme.typography.titleMedium
                )
                
                val resolutionText = instrument.resolution?.let { "$it m" } ?: "N/A"
                Text(
                    text = "Résolution: ",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@Preview
@Composable
fun InstrumentItemPreview() {
    InstrumentItem(
        instrument = Instrument("INST-01", "Camera Optique", "OptiCam-X", 0.5, 12.0),
        etatFonctionnement = "OK"
    )
}

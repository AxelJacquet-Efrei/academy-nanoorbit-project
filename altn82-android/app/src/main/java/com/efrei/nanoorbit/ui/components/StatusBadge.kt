package com.efrei.nanoorbit.ui.components

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.unit.dp
import androidx.compose.ui.tooling.preview.Preview
import com.efrei.nanoorbit.data.models.StatutSatellite

@Composable
fun StatusBadge(statut: StatutSatellite, modifier: Modifier = Modifier) {
    val backgroundColor = when (statut) {
        StatutSatellite.OPERATIONNEL -> Color(0xFF4CAF50)
        StatutSatellite.EN_VEILLE -> Color(0xFFFF9800)
        StatutSatellite.DEFAILLANT -> Color(0xFFF44336)
        StatutSatellite.DESORBITE -> Color(0xFF9E9E9E)
    }
    
    Surface(
        color = backgroundColor,
        shape = RoundedCornerShape(16.dp),
        modifier = modifier
    ) {
        Text(
            text = statut.intitule,
            color = Color.White,
            style = MaterialTheme.typography.labelSmall,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

@Preview
@Composable
fun StatusBadgePreview() {
    StatusBadge(statut = StatutSatellite.OPERATIONNEL)
}


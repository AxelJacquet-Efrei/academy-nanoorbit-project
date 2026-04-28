package com.efrei.nanoorbit.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.StatutSatellite

@Composable
fun SatelliteCard(
    satellite: Satellite,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isDesorbite = satellite.statut == StatutSatellite.DESORBITE
    val textColor = if (isDesorbite) {
        MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f)
    } else {
        MaterialTheme.colorScheme.onSurface
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(enabled = !isDesorbite, onClick = onClick),
        colors = if (isDesorbite) {
            CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f))
        } else {
            CardDefaults.cardColors()
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = satellite.nomSatellite,
                    style = MaterialTheme.typography.titleMedium,
                    color = textColor
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "ID: ${satellite.idSatellite} - ${satellite.formatCubesat} - ${satellite.typeOrbite}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (isDesorbite) {
                    Text("DESORBITE", style = MaterialTheme.typography.labelSmall, color = textColor)
                }
            }
            StatusBadge(statut = satellite.statut)
        }
    }
}

@Preview
@Composable
fun SatelliteCardPreview() {
    SatelliteCard(
        satellite = Satellite("SAT-001", "NanoOrbit-Alpha", StatutSatellite.OPERATIONNEL, "3U", "ORB-001", "SSO", 550, "2022-03-15", 1.3),
        onClick = {}
    )
}

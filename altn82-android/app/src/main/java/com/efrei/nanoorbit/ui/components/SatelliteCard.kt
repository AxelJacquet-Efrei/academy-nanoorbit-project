package com.efrei.nanoorbit.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.tooling.preview.Preview
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.StatutSatellite

@Composable
fun SatelliteCard(
    satellite: Satellite,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val currentStatut = (satellite.statut as StatutSatellite?) ?: StatutSatellite.DEFAILLANT
    val isDesorbite = currentStatut == StatutSatellite.DESORBITE
    val safeNomSatellite = (satellite.nomSatellite as String?)?.takeIf { it.isNotBlank() } ?: "Satellite inconnu"
    val safeIdSatellite = (satellite.idSatellite as String?)?.takeIf { it.isNotBlank() } ?: "UNKNOWN"
    val safeTypeOrbite = (satellite.typeOrbite as String?)?.takeIf { it.isNotBlank() } ?: "N/A"

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(enabled = !isDesorbite, onClick = onClick),
        colors = if (isDesorbite) {
            CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
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
            Column {
                Text(
                    text = safeNomSatellite,
                    style = MaterialTheme.typography.titleMedium,
                    color = if (isDesorbite) MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f) else MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "ID: $safeIdSatellite • Orbit type: $safeTypeOrbite",
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (isDesorbite) MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f) else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            StatusBadge(statut = currentStatut)
        }
    }
}

@Preview
@Composable
fun SatelliteCardPreview() {
    SatelliteCard(
        satellite = Satellite("SAT-001", "NanoObs-1", StatutSatellite.OPERATIONNEL, "3U", 1, "ORB-001", "2023-01-15", 4.5),
        onClick = {}
    )
}


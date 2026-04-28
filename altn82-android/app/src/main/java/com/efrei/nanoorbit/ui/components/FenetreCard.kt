package com.efrei.nanoorbit.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
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
import com.efrei.nanoorbit.data.models.FenetreCom

@Composable
fun FenetreCard(
    fenetre: FenetreCom,
    nomStation: String,
    modifier: Modifier = Modifier
) {
    val statutColor = when {
        fenetre.statut.contains("realisee", ignoreCase = true) -> Color(0xFF4CAF50)
        fenetre.statut.contains("annulee", ignoreCase = true) -> Color(0xFFF44336)
        else -> Color(0xFF2196F3)
    }

    Card(modifier = modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(text = nomStation, style = MaterialTheme.typography.titleMedium)
                Surface(color = statutColor, shape = RoundedCornerShape(16.dp)) {
                    Text(
                        text = fenetre.statut,
                        color = Color.White,
                        style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            Text("Satellite: ${fenetre.idSatellite}", style = MaterialTheme.typography.bodyMedium)
            Text("Debut: ${fenetre.datetimeDebut}", style = MaterialTheme.typography.bodyMedium)
            Text("Duree: ${fenetre.duree} s", style = MaterialTheme.typography.bodyMedium)
            fenetre.volumeDonnees?.let {
                Text("Volume: $it MB", style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}

@Preview
@Composable
fun FenetreCardPreview() {
    FenetreCard(
        fenetre = FenetreCom(1, "2026-04-28T10:30:00", 600, "Realisee", "SAT-001", "ST-KOU", 150.5),
        nomStation = "Kourou"
    )
}

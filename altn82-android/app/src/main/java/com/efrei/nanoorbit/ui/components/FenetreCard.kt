package com.efrei.nanoorbit.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.tooling.preview.Preview
import com.efrei.nanoorbit.data.models.FenetreCom
import androidx.compose.material3.Surface
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.Color

@Composable
fun FenetreCard(
    fenetre: FenetreCom,
    nomStation: String,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = nomStation,
                    style = MaterialTheme.typography.titleMedium
                )
                
                val statutColor = if (fenetre.statut == "Réalisée") Color(0xFF4CAF50) else Color(0xFF2196F3)
                
                Surface(
                    color = statutColor,
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Text(
                        text = fenetre.statut,
                        color = Color.White,
                        style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Début: ${fenetre.datetimeDebut}",
                style = MaterialTheme.typography.bodyMedium
            )
            Text(
                text = "Durée: ${fenetre.duree} s",
                style = MaterialTheme.typography.bodyMedium
            )
            if (fenetre.volumeDonnees != null) {
                Text(
                    text = "Volume: ${fenetre.volumeDonnees} MB",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@Preview
@Composable
fun FenetreCardPreview() {
    FenetreCard(
        fenetre = FenetreCom(1, "2024-05-20T10:30:00", 600, "Réalisée", "SAT-001", "ST-KOU", 150.5),
        nomStation = "Kourou"
    )
}


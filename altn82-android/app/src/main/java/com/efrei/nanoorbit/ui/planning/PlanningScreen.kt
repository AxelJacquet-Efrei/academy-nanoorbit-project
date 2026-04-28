package com.efrei.nanoorbit.ui.planning

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.efrei.nanoorbit.ui.components.FenetreCard
import com.efrei.nanoorbit.ui.dashboard.NanoOrbitViewModel

@Composable
fun PlanningScreen(
    viewModel: NanoOrbitViewModel,
    modifier: Modifier = Modifier
) {
    val fenetres by viewModel.filteredFenetres.collectAsStateWithLifecycle()
    val stations by viewModel.stations.collectAsStateWithLifecycle()
    val selectedStation by viewModel.selectedStationCode.collectAsStateWithLifecycle()
    val satellites by viewModel.satellites.collectAsStateWithLifecycle()
    var dureeText by remember { mutableStateOf("600") }
    var selectedSatelliteId by remember { mutableStateOf("SAT-001") }
    var validationMessage by remember { mutableStateOf<String?>(null) }

    val totalDuration = fenetres.sumOf { it.duree }
    val totalVolume = fenetres.mapNotNull { it.volumeDonnees }.sum()

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text("Planning communications", style = MaterialTheme.typography.headlineSmall)
            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = selectedStation == null,
                    onClick = { viewModel.onStationFilterChange(null) },
                    label = { Text("Toutes") }
                )
                stations.forEach { station ->
                    FilterChip(
                        selected = selectedStation == station.codeStation,
                        onClick = { viewModel.onStationFilterChange(station.codeStation) },
                        label = { Text(station.nomStation) }
                    )
                }
            }

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Synthese", style = MaterialTheme.typography.titleMedium)
                    Text("Contact total: $totalDuration s")
                    Text("Volume total planifie: ${"%.1f".format(totalVolume)} MB")
                }
            }

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Validation nouvelle fenetre", style = MaterialTheme.typography.titleMedium)
                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        satellites.forEach { satellite ->
                            FilterChip(
                                selected = selectedSatelliteId == satellite.idSatellite,
                                onClick = { selectedSatelliteId = satellite.idSatellite },
                                label = { Text(satellite.idSatellite) }
                            )
                        }
                    }
                    OutlinedTextField(
                        value = dureeText,
                        onValueChange = { dureeText = it.filter(Char::isDigit) },
                        label = { Text("Duree en secondes") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.fillMaxWidth()
                    )
                    Button(
                        onClick = {
                            val duree = dureeText.toIntOrNull() ?: 0
                            validationMessage = viewModel.validateFenetre(duree, selectedSatelliteId)
                                ?: "Fenetre valide cote client"
                        }
                    ) {
                        Text("Verifier RG-F04 / RG-S06")
                    }
                    validationMessage?.let {
                        Text(
                            text = it,
                            color = if (it.startsWith("Fenetre")) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.error
                        )
                    }
                }
            }
        }

        items(fenetres, key = { it.idFenetre }) { fenetre ->
            val stationName = stations.firstOrNull { it.codeStation == fenetre.codeStation }?.nomStation
                ?: fenetre.codeStation
            FenetreCard(fenetre = fenetre, nomStation = stationName)
        }
    }
}

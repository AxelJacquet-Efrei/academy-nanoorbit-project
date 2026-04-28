package com.efrei.nanoorbit.ui.detail

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.ui.components.InstrumentItem
import com.efrei.nanoorbit.ui.components.StatusBadge
import com.efrei.nanoorbit.ui.dashboard.NanoOrbitViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailScreen(
    satelliteId: String,
    viewModel: NanoOrbitViewModel,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val satellites by viewModel.satellites.collectAsStateWithLifecycle()
    val instrumentsBySatellite by viewModel.instrumentsBySatellite.collectAsStateWithLifecycle()
    val satellite = satellites.firstOrNull { it.idSatellite == satelliteId }
    val instruments = instrumentsBySatellite[satelliteId].orEmpty()
    var showDialog by remember { mutableStateOf(false) }
    var anomalyText by remember { mutableStateOf("") }
    var anomalyError by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(satelliteId) {
        viewModel.loadInstrumentsForSatellite(satelliteId)
    }

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = { Text(satellite?.nomSatellite ?: satelliteId) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Text("<")
                    }
                }
            )
        }
    ) { innerPadding ->
        if (satellite == null) {
            Text(
                text = "Satellite introuvable",
                modifier = Modifier.padding(innerPadding).padding(16.dp)
            )
        } else {
            val altitude = viewModel.findOrbiteAltitude(satellite.idOrbite)
            val batteryRatio = when (satellite.statut) {
                StatutSatellite.OPERATIONNEL -> 0.86f
                StatutSatellite.EN_VEILLE -> 0.62f
                StatutSatellite.DEFAILLANT -> 0.28f
                StatutSatellite.DESORBITE -> 0.0f
            }
            val lifeText = when (satellite.statut) {
                StatutSatellite.DESORBITE -> "Fin de vie"
                StatutSatellite.DEFAILLANT -> "Moins de 6 mois"
                else -> "Environ 3 ans"
            }

            Column(
                modifier = Modifier
                    .padding(innerPadding)
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                SectionTitle("Statut")
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                    StatusBadge(statut = satellite.statut)
                    Text("${satellite.formatCubesat} - ${satellite.typeOrbite}")
                }
                Text("Altitude: ${altitude?.let { "$it km" } ?: "N/A"}")

                SectionTitle("Telemetrie")
                Text("Masse: ${satellite.masse?.let { "$it kg" } ?: "N/A"}")
                Text("Batterie: ${(batteryRatio * 100).toInt()}%")
                LinearProgressIndicator(progress = { batteryRatio }, modifier = Modifier.fillMaxWidth())
                Text("Duree de vie restante: $lifeText")

                SectionTitle("Instruments embarques")
                if (instruments.isEmpty()) {
                    Text("Aucun instrument disponible")
                } else {
                    instruments.forEach { instrument ->
                        InstrumentItem(
                            instrument = instrument,
                            etatFonctionnement = if (satellite.statut == StatutSatellite.DEFAILLANT) "ALERTE" else "OK"
                        )
                    }
                }

                SectionTitle("Missions actives")
                val missions = viewModel.missionsForSatellite(satellite.idSatellite)
                if (missions.isEmpty()) {
                    Text("Aucune mission active")
                } else {
                    missions.forEach { (mission, role) ->
                        Text("${mission.nomMission} - $role")
                    }
                }

                Button(onClick = { showDialog = true }, modifier = Modifier.fillMaxWidth()) {
                    Text("Signaler une anomalie")
                }
            }
        }
    }

    if (showDialog) {
        AlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text("Signaler une anomalie") },
            text = {
                Column {
                    OutlinedTextField(
                        value = anomalyText,
                        onValueChange = {
                            anomalyText = it
                            anomalyError = null
                        },
                        label = { Text("Description") },
                        isError = anomalyError != null,
                        modifier = Modifier.fillMaxWidth()
                    )
                    anomalyError?.let {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(it, color = MaterialTheme.colorScheme.error)
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (anomalyText.isBlank()) {
                            anomalyError = "La description est obligatoire"
                        } else {
                            anomalyText = ""
                            showDialog = false
                        }
                    }
                ) {
                    Text("Envoyer")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDialog = false }) {
                    Text("Annuler")
                }
            }
        )
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(text = text, style = MaterialTheme.typography.titleLarge)
}

package com.efrei.nanoorbit.ui.dashboard

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.ui.components.OfflineBanner
import com.efrei.nanoorbit.ui.components.SatelliteCard

/*
 * Q1: LazyColumn ne compose que les cartes visibles. Une Column avec 100 satellites
 * composerait tout d'un coup, avec plus de memoire et un demarrage plus lent.
 *
 * Q2: Une enum class limite les statuts aux valeurs du CHECK Oracle et evite les fautes
 * de frappe qu'une String libre laisserait passer.
 *
 * Q3: La UI bloque les actions sur SAT-005 desorbite et la validation planning refuse
 * toute fenetre. Le trigger Oracle reste la securite serveur definitive.
 */
@Composable
fun DashboardScreen(
    viewModel: NanoOrbitViewModel,
    onSatelliteClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val errorMessage by viewModel.errorMessage.collectAsStateWithLifecycle()
    val filteredSatellites by viewModel.filteredSatellites.collectAsStateWithLifecycle()
    val searchQuery by viewModel.searchQuery.collectAsStateWithLifecycle()
    val selectedStatut by viewModel.selectedStatut.collectAsStateWithLifecycle()
    val isOffline by viewModel.isOffline.collectAsStateWithLifecycle()
    val cacheAgeMillis by viewModel.cacheAgeMillis.collectAsStateWithLifecycle()

    if (isLoading && filteredSatellites.isEmpty()) {
        Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    if (errorMessage != null && filteredSatellites.isEmpty()) {
        Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Erreur : $errorMessage", color = MaterialTheme.colorScheme.error)
                Spacer(modifier = Modifier.height(8.dp))
                Button(onClick = { viewModel.loadAll() }) {
                    Text("Reessayer")
                }
            }
        }
        return
    }

    val operationnelsCount = filteredSatellites.count { it.statut == StatutSatellite.OPERATIONNEL }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            if (isOffline) {
                OfflineBanner(cacheAgeMillis = cacheAgeMillis)
                Spacer(modifier = Modifier.height(8.dp))
            }

            OutlinedTextField(
                value = searchQuery,
                onValueChange = viewModel::onSearchQueryChange,
                label = { Text("Rechercher par nom ou type d'orbite") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = selectedStatut == null,
                    onClick = { viewModel.onStatutFilterChange(null) },
                    label = { Text("Tous") }
                )
                StatutSatellite.values().forEach { status ->
                    FilterChip(
                        selected = selectedStatut == status,
                        onClick = { viewModel.onStatutFilterChange(status) },
                        label = { Text(status.intitule) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "$operationnelsCount/${filteredSatellites.size} satellites operationnels",
                style = MaterialTheme.typography.titleMedium
            )
        }

        items(filteredSatellites, key = { it.idSatellite }) { satellite ->
            SatelliteCard(
                satellite = satellite,
                onClick = { onSatelliteClick(satellite.idSatellite) }
            )
        }
    }
}

package com.efrei.nanoorbit.ui.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.ui.components.SatelliteCard

/*
 * Réponses aux questions de réflexion:
 *
 * Q1: On utilise LazyColumn plutôt que Column car LazyColumn ne compose que les éléments
 *     visibles à l'écran et recycle les vues lorsqu'on scrolle. Avec 100 satellites, une Column classique
 *     instancierait et dessinerait les 100 éléments d'un coup, ce qui ferait chuter les performances,
 *     utiliserait beaucoup de mémoire et ralentirait l'initialisation de l'écran.
 *
 * Q2: Utiliser une enum class Kotlin plutôt qu'un String libre garantit la sécurité de typage 
 *     (type-safety) à la compilation. Cela empêche les fautes de frappe ("en veille" vs "En veille"),
 *     assure que le champ ne peut prendre aucune autre valeur que celles permises par le `CHECK` Oracle,
 *     et facilite l'utilisation du bloc `when` (exhaustivité vérifiée par le compilateur).
 *
 * Q3: L'application peut empêcher l'utilisateur de planifier en l'empêchant de cliquer sur
 *     la carte du satellite (via un état disabled sur le bouton ou la Row globale si le statut
 *     est DESORBITE) ou en masquant le bouton d'action. C'est une validation côté client,
 *     qui reflète la règle du trigger T1 côté Oracle. Le trigger assure l'intégrité de la
 *     base quelles que soient les requêtes (sécurité ultime serveur), tandis que la UI améliore 
 *     l'UX en évitant à l'utilisateur de faire une action qui va de toute façon échouer.
 */

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    modifier: Modifier = Modifier,
    viewModel: NanoOrbitViewModel = viewModel()
) {
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val errorMessage by viewModel.errorMessage.collectAsStateWithLifecycle()
    val filteredSatellites by viewModel.filteredSatellites.collectAsStateWithLifecycle()
    val searchQuery by viewModel.searchQuery.collectAsStateWithLifecycle()
    val selectedStatut by viewModel.selectedStatut.collectAsStateWithLifecycle()
    
    if (isLoading) {
        Box(modifier = modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) {
            CircularProgressIndicator()
        }
    } else if (errorMessage != null) {
        Box(modifier = modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) {
            Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                Text("Erreur : $errorMessage", color = MaterialTheme.colorScheme.error)
                Spacer(modifier = Modifier.height(8.dp))
                Button(onClick = { viewModel.loadSatellites() }) {
                    Text("Réessayer")
                }
            }
        }
    } else {
        val operationnelsCount = filteredSatellites.count { it.statut == StatutSatellite.OPERATIONNEL }
        
        Column(modifier = modifier.fillMaxSize().padding(16.dp)) {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { viewModel.onSearchQueryChange(it) },
                label = { Text("Rechercher par nom ou type d'orbite") },
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(8.dp))

            // L2-C: Filtres statut fonctionnels
            Row(
                modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
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
                text = "$operationnelsCount/${filteredSatellites.size} satellites opérationnels",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(filteredSatellites) { satellite ->
                    SatelliteCard(
                        satellite = satellite,
                        onClick = { /* Navigation vers DetailScreen dans la Phase 2 */ }
                    )
                }
            }
        }
    }
}

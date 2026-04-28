package com.efrei.nanoorbit.ui.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.data.repository.NanoOrbitRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class NanoOrbitViewModel : ViewModel() {
    private val repository = NanoOrbitRepository()

    private val _satellites = MutableStateFlow<List<Satellite>>(emptyList())
    val satellites: StateFlow<List<Satellite>> = _satellites.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _selectedStatut = MutableStateFlow<StatutSatellite?>(null)
    val selectedStatut: StateFlow<StatutSatellite?> = _selectedStatut.asStateFlow()

    val filteredSatellites: StateFlow<List<Satellite>> = combine(
        _satellites, _searchQuery, _selectedStatut
    ) { list, query, status ->
        list.filter { satellite ->
            val nom = satellite.nomSatellite
            val orbitType = satellite.typeOrbite
            val matchQuery = nom.contains(query, ignoreCase = true) || orbitType.contains(query, ignoreCase = true)
            val matchStatus = status == null || satellite.statut == status
            matchQuery && matchStatus
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        loadSatellites()
    }

    fun loadSatellites() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                _satellites.value = repository.getSatellites()
            } catch (e: Exception) {
                _errorMessage.value = e.message ?: "Erreur réseau inconnue"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun refreshSatellites() {
        loadSatellites()
    }

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
    }

    fun onStatutFilterChange(statut: StatutSatellite?) {
        _selectedStatut.value = statut
    }

    // L2-D : Validation RG-F04
    // Règle côté client : La durée d'une fenêtre de communication est bornée à [1, 900] secondes.
    // Lien avec ALTN83 : Cela correspond au trigger Oracle T3 `CHECK (duree BETWEEN 1 AND 900)` côté serveur.
    fun validateFenetreDuree(duree: Int): Boolean {
        return duree in 1..900
    }

    fun getFenetreDureeError(duree: Int): String? {
        return if (validateFenetreDuree(duree)) null else "La durée doit être comprise entre 1 et 900 secondes."
    }
}


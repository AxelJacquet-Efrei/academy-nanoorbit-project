package com.efrei.nanoorbit.ui.dashboard

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.Instrument
import com.efrei.nanoorbit.data.models.Mission
import com.efrei.nanoorbit.data.models.Orbite
import com.efrei.nanoorbit.data.models.ParticipationMission
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.StationSol
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.data.repository.NanoOrbitRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class NanoOrbitViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = NanoOrbitRepository(application)

    private val _satellites = MutableStateFlow<List<Satellite>>(emptyList())
    val satellites: StateFlow<List<Satellite>> = _satellites.asStateFlow()

    private val _fenetres = MutableStateFlow<List<FenetreCom>>(emptyList())
    val fenetres: StateFlow<List<FenetreCom>> = _fenetres.asStateFlow()

    private val _stations = MutableStateFlow<List<StationSol>>(emptyList())
    val stations: StateFlow<List<StationSol>> = _stations.asStateFlow()

    private val _orbites = MutableStateFlow<List<Orbite>>(emptyList())
    val orbites: StateFlow<List<Orbite>> = _orbites.asStateFlow()

    private val _missions = MutableStateFlow<List<Mission>>(emptyList())
    val missions: StateFlow<List<Mission>> = _missions.asStateFlow()

    private val _participations = MutableStateFlow<List<ParticipationMission>>(emptyList())
    val participations: StateFlow<List<ParticipationMission>> = _participations.asStateFlow()

    private val _instrumentsBySatellite = MutableStateFlow<Map<String, List<Instrument>>>(emptyMap())
    val instrumentsBySatellite: StateFlow<Map<String, List<Instrument>>> = _instrumentsBySatellite.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _isOffline = MutableStateFlow(false)
    val isOffline: StateFlow<Boolean> = _isOffline.asStateFlow()

    private val _cacheAgeMillis = MutableStateFlow<Long?>(null)
    val cacheAgeMillis: StateFlow<Long?> = _cacheAgeMillis.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _selectedStatut = MutableStateFlow<StatutSatellite?>(null)
    val selectedStatut: StateFlow<StatutSatellite?> = _selectedStatut.asStateFlow()

    private val _selectedStationCode = MutableStateFlow<String?>(null)
    val selectedStationCode: StateFlow<String?> = _selectedStationCode.asStateFlow()

    val filteredSatellites: StateFlow<List<Satellite>> = combine(
        _satellites, _searchQuery, _selectedStatut
    ) { list, query, status ->
        list.filter { satellite ->
            val matchQuery = satellite.nomSatellite.contains(query, ignoreCase = true) ||
                satellite.typeOrbite.contains(query, ignoreCase = true)
            val matchStatus = status == null || satellite.statut == status
            matchQuery && matchStatus
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val filteredFenetres: StateFlow<List<FenetreCom>> = combine(
        _fenetres, _selectedStationCode
    ) { list, station ->
        list
            .filter { station == null || it.codeStation == station }
            .sortedBy { it.datetimeDebut }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        loadAll()
    }

    fun loadAll() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                val satelliteResult = repository.getSatellitesCacheFirst()
                _satellites.value = satelliteResult.data
                _isOffline.value = satelliteResult.fromCache
                _cacheAgeMillis.value = satelliteResult.cacheAgeMillis

                val fenetreResult = repository.getFenetresCacheFirst()
                _fenetres.value = fenetreResult.data
                if (fenetreResult.fromCache) {
                    _isOffline.value = true
                    _cacheAgeMillis.value = fenetreResult.cacheAgeMillis
                }

                _stations.value = repository.getStations()
                _orbites.value = repository.getOrbites()
                _missions.value = repository.getMissions()
                _participations.value = repository.getParticipations()

                if (satelliteResult.fromCache || fenetreResult.fromCache) {
                    val refreshedSatellites = repository.refreshSatellites()
                    val refreshedFenetres = repository.refreshFenetres()
                    _satellites.value = refreshedSatellites.data
                    _fenetres.value = refreshedFenetres.data
                    _isOffline.value = false
                    _cacheAgeMillis.value = 0
                }
            } catch (e: Exception) {
                _errorMessage.value = e.message ?: "Erreur reseau inconnue"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun refreshSatellites() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            try {
                val satellites = repository.refreshSatellites()
                val fenetres = repository.refreshFenetres()
                _satellites.value = satellites.data
                _fenetres.value = fenetres.data
                _stations.value = repository.getStations()
                _orbites.value = repository.getOrbites()
                _missions.value = repository.getMissions()
                _participations.value = repository.getParticipations()
                _isOffline.value = false
                _cacheAgeMillis.value = 0
            } catch (e: Exception) {
                _errorMessage.value = e.message ?: "Erreur reseau inconnue"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun loadInstrumentsForSatellite(id: String) {
        if (_instrumentsBySatellite.value.containsKey(id)) return
        viewModelScope.launch {
            val instruments = repository.getInstruments(id)
            _instrumentsBySatellite.value = _instrumentsBySatellite.value + (id to instruments)
        }
    }

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
    }

    fun onStatutFilterChange(statut: StatutSatellite?) {
        _selectedStatut.value = statut
    }

    fun onStationFilterChange(codeStation: String?) {
        _selectedStationCode.value = codeStation
    }

    fun findSatellite(id: String): Satellite? = _satellites.value.firstOrNull { it.idSatellite == id }

    fun missionsForSatellite(id: String): List<Pair<Mission, String>> {
        val activeMissions = _missions.value.filter { it.statutMission.equals("Active", ignoreCase = true) }
        return _participations.value
            .filter { it.idSatellite == id }
            .mapNotNull { participation ->
                activeMissions.firstOrNull { it.idMission == participation.idMission }?.let { it to participation.role }
            }
    }

    fun validateFenetre(duree: Int, idSatellite: String): String? {
        return repository.validateFenetre(duree, findSatellite(idSatellite))
    }
}

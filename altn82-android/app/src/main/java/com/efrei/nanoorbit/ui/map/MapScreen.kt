package com.efrei.nanoorbit.ui.map

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.drawable.GradientDrawable
import android.location.Location
import android.location.LocationManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.efrei.nanoorbit.data.models.StationSol
import com.efrei.nanoorbit.ui.dashboard.NanoOrbitViewModel
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker

@Composable
fun MapScreen(
    viewModel: NanoOrbitViewModel,
    modifier: Modifier = Modifier
) {
    val stations by viewModel.stations.collectAsStateWithLifecycle()
    val context = LocalContext.current
    var currentLocation by remember { mutableStateOf<Location?>(null) }
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            currentLocation = context.lastKnownLocation()
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { ctx ->
                MapView(ctx).apply {
                    setTileSource(TileSourceFactory.MAPNIK)
                    setMultiTouchControls(true)
                    controller.setZoom(3.0)
                    controller.setCenter(GeoPoint(35.0, 10.0))
                }
            },
            update = { map ->
                map.overlays.clear()
                stations.forEach { station ->
                    val marker = Marker(map).apply {
                        position = GeoPoint(station.latitude, station.longitude)
                        setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
                        title = station.nomStation
                        subDescription = station.description(currentLocation)
                        icon = stationMarkerDrawable(context, station)
                    }
                    map.overlays.add(marker)
                }
                currentLocation?.let { location ->
                    map.controller.animateTo(GeoPoint(location.latitude, location.longitude))
                }
                map.invalidate()
            }
        )

        FloatingActionButton(
            onClick = {
                val hasPermission = ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED

                if (hasPermission) {
                    currentLocation = context.lastKnownLocation()
                } else {
                    permissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
                }
            },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(24.dp)
        ) {
            Text("GPS")
        }
    }
}

private fun StationSol.description(currentLocation: Location?): String {
    val distance = currentLocation?.let {
        val result = FloatArray(1)
        Location.distanceBetween(it.latitude, it.longitude, latitude, longitude, result)
        " - ${(result[0] / 1000).toInt()} km"
    } ?: ""
    return "Etat: $etat - Bande $bandeFrequence - Debit max: ${debitMax ?: "N/A"} Mbps$distance"
}

private fun stationMarkerDrawable(context: Context, station: StationSol): GradientDrawable {
    val color = when {
        station.etat.contains("maintenance", ignoreCase = true) -> 0xFFFF9800.toInt()
        station.etat.contains("hors", ignoreCase = true) -> 0xFF9E9E9E.toInt()
        else -> 0xFF4CAF50.toInt()
    }
    return GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(color)
        setStroke(3, 0xFFFFFFFF.toInt())
        setSize(42, 42)
    }
}

private fun Context.lastKnownLocation(): Location? {
    val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
    val providers = manager.getProviders(true)
    return providers.mapNotNull { provider ->
        runCatching {
            if (
                ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
            ) {
                manager.getLastKnownLocation(provider)
            } else {
                null
            }
        }.getOrNull()
    }.maxByOrNull { it.time }
}

package com.efrei.nanoorbit

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import com.efrei.nanoorbit.notifications.CommunicationWindowWorker
import com.efrei.nanoorbit.notifications.NanoOrbitNotificationHelper
import com.efrei.nanoorbit.ui.navigation.NanoOrbitApp
import com.efrei.nanoorbit.ui.navigation.Routes
import com.efrei.nanoorbit.ui.theme.NanoOrbitTheme
import org.osmdroid.config.Configuration

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Configuration.getInstance().userAgentValue = packageName
        NanoOrbitNotificationHelper.ensureChannel(this)
        CommunicationWindowWorker.schedule(this)
        val startRoute = intent.getStringExtra(EXTRA_START_ROUTE) ?: Routes.Dashboard
        enableEdgeToEdge()
        setContent {
            NanoOrbitTheme {
                NanoOrbitApp(
                    modifier = Modifier.fillMaxSize(),
                    startDestination = startRoute
                )
            }
        }
    }

    companion object {
        const val EXTRA_START_ROUTE = "extra_start_route"
    }
}

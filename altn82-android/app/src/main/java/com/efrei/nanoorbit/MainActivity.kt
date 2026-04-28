package com.efrei.nanoorbit

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import com.efrei.nanoorbit.ui.navigation.NanoOrbitApp
import com.efrei.nanoorbit.ui.theme.NanoOrbitTheme
import org.osmdroid.config.Configuration

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Configuration.getInstance().userAgentValue = packageName
        enableEdgeToEdge()
        setContent {
            NanoOrbitTheme {
                NanoOrbitApp(modifier = Modifier.fillMaxSize())
            }
        }
    }
}

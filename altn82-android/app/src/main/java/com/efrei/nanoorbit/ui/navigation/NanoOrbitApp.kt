package com.efrei.nanoorbit.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.efrei.nanoorbit.ui.dashboard.DashboardScreen
import com.efrei.nanoorbit.ui.dashboard.NanoOrbitViewModel
import com.efrei.nanoorbit.ui.detail.DetailScreen
import com.efrei.nanoorbit.ui.map.MapScreen
import com.efrei.nanoorbit.ui.planning.PlanningScreen

@Composable
fun NanoOrbitApp(
    modifier: Modifier = Modifier,
    startDestination: String = Routes.Dashboard
) {
    val navController = rememberNavController()
    val viewModel: NanoOrbitViewModel = viewModel()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val showBottomBar = currentRoute != Routes.Detail

    Scaffold(
        modifier = modifier,
        bottomBar = {
            if (showBottomBar) {
                BottomNavigationBar(
                    currentRoute = currentRoute,
                    onNavigate = { route ->
                        navController.navigate(route) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState = true
                        }
                    }
                )
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = startDestination,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Routes.Dashboard) {
                DashboardScreen(
                    viewModel = viewModel,
                    onSatelliteClick = { navController.navigate(Routes.detail(it)) }
                )
            }
            composable(
                route = Routes.Detail,
                arguments = listOf(navArgument("satelliteId") { type = NavType.StringType })
            ) { entry ->
                DetailScreen(
                    satelliteId = entry.arguments?.getString("satelliteId").orEmpty(),
                    viewModel = viewModel,
                    onBack = { navController.popBackStack() }
                )
            }
            composable(Routes.Planning) {
                PlanningScreen(viewModel = viewModel)
            }
            composable(Routes.Map) {
                MapScreen(viewModel = viewModel)
            }
        }
    }
}

@Composable
private fun BottomNavigationBar(
    currentRoute: String?,
    onNavigate: (String) -> Unit
) {
    val items = listOf(
        Routes.Dashboard to "Dashboard",
        Routes.Planning to "Planning",
        Routes.Map to "Carte"
    )

    NavigationBar {
        items.forEach { (route, label) ->
            NavigationBarItem(
                selected = currentRoute == route,
                onClick = { onNavigate(route) },
                icon = { Text(label.first().toString()) },
                label = { Text(label) }
            )
        }
    }
}

package com.efrei.nanoorbit.ui.navigation

object Routes {
    const val Dashboard = "dashboard"
    const val Planning = "planning"
    const val Map = "map"
    const val Detail = "detail/{satelliteId}"

    fun detail(satelliteId: String): String = "detail/$satelliteId"
}

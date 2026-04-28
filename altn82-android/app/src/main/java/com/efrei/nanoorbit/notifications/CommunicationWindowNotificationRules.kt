package com.efrei.nanoorbit.notifications

import com.efrei.nanoorbit.data.models.FenetreCom
import java.time.LocalDateTime

private const val PLANNED_STATUS = "planifiee"

fun isCommunicationWindowNotificationEligible(
    fenetre: FenetreCom,
    now: LocalDateTime,
    notifiedIds: Set<Int>,
    leadMinutes: Long = 15,
    toleranceMinutes: Long = 2
): Boolean {
    if (fenetre.idFenetre in notifiedIds) return false
    if (fenetre.statut.normalizedStatus() != PLANNED_STATUS) return false

    val start = fenetre.datetimeDebut.toLocalDateTimeOrNull() ?: return false
    val lowerBound = now.plusMinutes(leadMinutes - toleranceMinutes)
    val upperBound = now.plusMinutes(leadMinutes + toleranceMinutes)

    return !start.isBefore(lowerBound) && !start.isAfter(upperBound)
}

fun String.toLocalDateTimeOrNull(): LocalDateTime? {
    val normalized = trim()
        .replace(" ", "T")
        .substringBefore(".")
    return runCatching { LocalDateTime.parse(normalized) }.getOrNull()
}

private fun String.normalizedStatus(): String {
    return lowercase()
        .replace("é", "e")
        .replace("è", "e")
        .replace("ê", "e")
        .replace("Ã©", "e")
        .replace("Ã¨", "e")
        .replace("Ãª", "e")
        .trim()
}

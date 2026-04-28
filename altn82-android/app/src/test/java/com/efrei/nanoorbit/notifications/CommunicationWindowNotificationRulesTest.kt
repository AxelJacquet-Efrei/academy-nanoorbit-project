package com.efrei.nanoorbit.notifications

import com.efrei.nanoorbit.data.models.FenetreCom
import java.time.LocalDateTime
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CommunicationWindowNotificationRulesTest {
    private val now = LocalDateTime.of(2026, 4, 29, 12, 0)

    @Test
    fun plannedWindowAtLeadTimeIsEligible() {
        val fenetre = fenetre(
            datetimeDebut = now.plusMinutes(15).toString(),
            statut = "Planifiee"
        )

        assertTrue(isCommunicationWindowNotificationEligible(fenetre, now, emptySet()))
    }

    @Test
    fun realizedWindowIsIgnored() {
        val fenetre = fenetre(
            datetimeDebut = now.plusMinutes(15).toString(),
            statut = "Realisee"
        )

        assertFalse(isCommunicationWindowNotificationEligible(fenetre, now, emptySet()))
    }

    @Test
    fun alreadyNotifiedWindowIsIgnored() {
        val fenetre = fenetre(
            idFenetre = 42,
            datetimeDebut = now.plusMinutes(15).toString(),
            statut = "Planifiee"
        )

        assertFalse(isCommunicationWindowNotificationEligible(fenetre, now, setOf(42)))
    }

    @Test
    fun pastWindowIsIgnored() {
        val fenetre = fenetre(
            datetimeDebut = now.minusMinutes(1).toString(),
            statut = "Planifiee"
        )

        assertFalse(isCommunicationWindowNotificationEligible(fenetre, now, emptySet()))
    }

    private fun fenetre(
        idFenetre: Int = 1,
        datetimeDebut: String,
        statut: String
    ): FenetreCom = FenetreCom(
        idFenetre = idFenetre,
        datetimeDebut = datetimeDebut,
        duree = 420,
        statut = statut,
        idSatellite = "SAT-001",
        codeStation = "GS-KIR-01",
        volumeDonnees = null
    )
}

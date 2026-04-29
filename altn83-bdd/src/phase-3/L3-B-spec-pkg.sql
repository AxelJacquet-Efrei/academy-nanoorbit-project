ALTER SESSION SET CURRENT_SCHEMA = ACADEMY_NANOORBIT_PROJECT;

CREATE OR REPLACE PACKAGE pkg_nanoOrbit AS

    -- --------------------------------------------------------
    -- TYPE PUBLIC : t_stats_satellite
    -- Enregistrement retourne par la fonction stats_satellite.
    -- Contient les indicateurs de performance d'un satellite.
    -- --------------------------------------------------------
    TYPE t_stats_satellite IS RECORD (
        nb_fenetres          NUMBER,
        volume_total         NUMBER,
        duree_moy_secondes   NUMBER
    );

    -- --------------------------------------------------------
    -- CONSTANTES METIER
    -- --------------------------------------------------------

    c_statut_min_fenetre  CONSTANT VARCHAR2(30) := 'Operationnel';
    c_duree_max_fenetre   CONSTANT NUMBER       := 900;
    c_seuil_revision      CONSTANT NUMBER       := 50;

    -- --------------------------------------------------------
    -- PROCEDURE planifier_fenetre
    --
    -- Cree une nouvelle fenetre de communication (statut='Planifiee').
    -- Declenche automatiquement les triggers T1 (validation satellite/station)
    -- et T2 (anti-chevauchement) et T3 (force volume_donnees a NULL).
    --
    -- Parametres :
    --   p_id_satellite   IN  : identifiant du satellite (ex: 'SAT-001')
    --   p_code_station   IN  : code de la station (ex: 'GS-KIR-01')
    --   p_datetime_debut IN  : debut du creneau (TIMESTAMP)
    --   p_duree          IN  : duree en secondes (1..900 -- CHECK RG-F04)
    --   p_id_fenetre     OUT : identifiant auto-incremente retourne
    --
    -- Codes erreur (range -20100 a -20109) :
    --   -20100 : duree hors domaine [1..900]
    --   -20101 : satellite ou station introuvable (FK violation)
    --   Les triggers T1/T2 peuvent lever -20001, -20002, -20003, -20004
    -- --------------------------------------------------------
    PROCEDURE planifier_fenetre(
        p_id_satellite   IN  VARCHAR2,
        p_code_station   IN  VARCHAR2,
        p_datetime_debut IN  TIMESTAMP,
        p_duree          IN  NUMBER,
        p_id_fenetre     OUT NUMBER
    );

    -- --------------------------------------------------------
    -- PROCEDURE cloturer_fenetre
    --
    -- Passe une fenetre planifiee en statut 'Realisee'
    -- et enregistre le volume effectivement telecharge.
    --
    -- Parametres :
    --   p_id_fenetre     IN : identifiant de la fenetre a cloturer
    --   p_volume_donnees IN : volume en Mo (doit etre > 0)
    --
    -- Codes erreur :
    --   -20110 : fenetre introuvable
    --   -20111 : fenetre deja cloturee (statut != 'Planifiee')
    --   -20112 : volume invalide (<= 0)
    -- --------------------------------------------------------
    PROCEDURE cloturer_fenetre(
        p_id_fenetre     IN NUMBER,
        p_volume_donnees IN NUMBER
    );

    -- --------------------------------------------------------
    -- PROCEDURE affecter_satellite_mission
    --
    -- Affecte un satellite a une mission avec un role defini.
    -- Declenche automatiquement le trigger T4 (mission Terminee)
    -- et verifie RG-S06 (satellite Desorbite).
    --
    -- Parametres :
    --   p_id_satellite IN : identifiant du satellite
    --   p_id_mission   IN : identifiant de la mission
    --   p_role         IN : role dans la mission (ex: 'Imageur principal')
    --
    -- Codes erreur :
    --   -20120 : participation deja existante (PK composite)
    --   Les triggers T4 peuvent lever -20005, -20006
    -- --------------------------------------------------------
    PROCEDURE affecter_satellite_mission(
        p_id_satellite IN VARCHAR2,
        p_id_mission   IN VARCHAR2,
        p_role         IN VARCHAR2
    );

    -- --------------------------------------------------------
    -- PROCEDURE mettre_en_revision
    --
    -- Passe un satellite en statut 'Defaillant'.
    -- Declenche le trigger T5 qui journalise le changement
    -- dans HISTORIQUE_STATUT.
    -- Note : Oracle ne supporte pas de statut 'En revision'
    --        (contrainte CHECK DDL) -- 'Defaillant' est utilise.
    --
    -- Parametres :
    --   p_id_satellite IN : identifiant du satellite
    --
    -- Codes erreur :
    --   -20130 : satellite introuvable
    --   -20131 : satellite deja Defaillant ou Desorbite
    -- --------------------------------------------------------
    PROCEDURE mettre_en_revision(
        p_id_satellite IN VARCHAR2
    );

    -- --------------------------------------------------------
    -- FONCTION calculer_volume_theorique
    --
    -- Retourne le volume theorique d'une fenetre en Mo :
    --   volume = (debit_station_Mbps / 8) * duree_secondes
    -- Equivalent standalone de la fonction Ex.16 (L3-A).
    --
    -- Parametres :
    --   p_id_fenetre IN : identifiant de la fenetre
    --
    -- Retour : NUMBER -- volume en Mo (NULL si introuvable)
    --
    -- Codes erreur :
    --   -20140 : fenetre introuvable
    -- --------------------------------------------------------
    FUNCTION calculer_volume_theorique(
        p_id_fenetre IN NUMBER
    ) RETURN NUMBER;

    -- --------------------------------------------------------
    -- FONCTION statut_constellation
    --
    -- Retourne un resume textuel de l'etat de la constellation.
    -- Format : "X/Y satellites operationnels, Z missions actives"
    --
    -- Exemple : "3/5 satellites operationnels, 2 missions actives"
    -- --------------------------------------------------------
    FUNCTION statut_constellation RETURN VARCHAR2;

    -- --------------------------------------------------------
    -- FONCTION stats_satellite
    --
    -- Retourne les indicateurs de performance d'un satellite
    -- sous forme de t_stats_satellite.
    -- Seules les fenetres 'Realisees' sont comptabilisees.
    --
    -- Parametres :
    --   p_id_satellite IN : identifiant du satellite
    --
    -- Retour : t_stats_satellite
    --   .nb_fenetres        : nombre de fenetres realisees
    --   .volume_total       : somme des volumes (Mo)
    --   .duree_moy_secondes : duree moyenne (s)
    --
    -- Codes erreur :
    --   -20150 : satellite introuvable
    -- --------------------------------------------------------
    FUNCTION stats_satellite(
        p_id_satellite IN VARCHAR2
    ) RETURN t_stats_satellite;

END pkg_nanoOrbit;
/
SHOW ERRORS;

-- ============================================================
-- VERIFICATION : la SPEC doit afficher "No errors."
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Verification SPEC pkg_nanoOrbit ===');
    DBMS_OUTPUT.PUT_LINE('Statut min fenetre : ' || pkg_nanoOrbit.c_statut_min_fenetre);
    DBMS_OUTPUT.PUT_LINE('Duree max fenetre  : ' || pkg_nanoOrbit.c_duree_max_fenetre || ' s');
    DBMS_OUTPUT.PUT_LINE('Seuil revision     : ' || pkg_nanoOrbit.c_seuil_revision || ' fenetres');
    DBMS_OUTPUT.PUT_LINE('[OK] Constantes accessibles -- SPEC compilee correctement.');
END;
/

-- ============================================================
-- Vérification
-- ============================================================

SELECT object_name, object_type, status
FROM   user_objects
WHERE  object_name = 'PKG_NANOORBIT'
ORDER  BY object_type;

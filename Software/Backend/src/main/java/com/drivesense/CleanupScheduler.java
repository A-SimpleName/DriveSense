package com.drivesense;

import com.drivesense.db.AccountDao;
import com.drivesense.db.GroupInvitationDao;
import com.drivesense.db.VehicleInvitationDao;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Geplante Aufgaben für Daten-Hygiene.
 * Läuft periodisch und führt Batch-Updates durch, die nicht transaktionssensitiv
 * sind (z.B. EXPIRED-Markierung bei Einladungen).
 */
@Component
public class CleanupScheduler {

    @Autowired private AccountDao          accountDao;
    @Autowired private GroupInvitationDao  groupInvitationDao;
    @Autowired private VehicleInvitationDao vehicleInvitationDao;

    /**
     * Löscht nicht-verifizierte Accounts, die älter als 24 Stunden sind.
     * Diese Accounts wurden nie aktiviert, daher ist ein physisches Löschen sicher.
     * Läuft täglich um 03:00 Uhr.
     */
    @Scheduled(cron = "0 0 3 * * *")
    public void deleteUnverifiedAccounts() {
        accountDao.deleteUnverifiedOlderThan24Hours();
    }

    /**
     * Markiert alle abgelaufenen Gruppen-Einladungen als EXPIRED.
     * Läuft jede Stunde.
     */
    @Scheduled(fixedRate = 60 * 60 * 1000)
    public void expireGroupInvitations() {
        groupInvitationDao.expireOldInvitations();
    }

    /**
     * Markiert alle abgelaufenen Fahrzeug-Einladungen als EXPIRED.
     * Läuft jede Stunde.
     */
    @Scheduled(fixedRate = 60 * 60 * 1000)
    public void expireVehicleInvitations() {
        vehicleInvitationDao.expireOldInvitations();
    }
}

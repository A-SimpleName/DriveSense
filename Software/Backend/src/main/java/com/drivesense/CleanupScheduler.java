package com.drivesense;

import com.drivesense.db.AccountDao;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class CleanupScheduler {
    @Autowired
    private AccountDao accountDao;

    // Jeden Tag um 3:00 Uhr nachts
    @Scheduled(cron = "0 0 3 * * *")
    public void deleteUnverifiedAccounts() {
        accountDao.deleteUnverifiedOlderThan24Hours();
    }
}

package com.drivesense.service;
import com.drivesense.db.AccountDao;
import com.drivesense.db.EmailVerificationDao;
import com.drivesense.exceptions.BadRequestException;
import com.drivesense.exceptions.NotFoundException;
import com.drivesense.model.EmailVerification;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class EmailVerificationService {
    @Autowired
    private EmailVerificationDao emailVerificationDao;
    @Autowired
    private AccountDao accountDao;
    @Autowired
    private EmailService emailService;

    // ──────────────────────────────────────────
    // CODE GENERIEREN + EMAIL SENDEN
    // ──────────────────────────────────────────

    public void sendVerificationCode(int accountId, String email) {
        // Alte Codes löschen
        emailVerificationDao.deleteByAccountId(accountId);

        String code = generateCode();
        String codeHash = BCrypt.hashpw(code, BCrypt.gensalt());

        EmailVerification ev = new EmailVerification();
        ev.setAccountId(accountId);
        ev.setCodeHash(codeHash);
        ev.setExpiresAt(LocalDateTime.now().plusMinutes(15));
        emailVerificationDao.insert(ev);

        emailService.sendVerificationCode(email, code);
    }

    // ──────────────────────────────────────────
    // CODE PRÜFEN → ACCOUNT VERIFIZIEREN
    // ──────────────────────────────────────────

    public void verifyCode(int accountId, String code) {
        List<EmailVerification> codes = emailVerificationDao.getAllByAccountId(accountId);

        if (codes == null || codes.isEmpty()) {
            throw new BadRequestException("Kein Verifizierungscode gefunden");
        }

        EmailVerification valid = codes.stream()
                .filter(ev -> BCrypt.checkpw(code, ev.getCodeHash()))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("Ungültiger Code"));

        if (valid.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new BadRequestException("Code ist abgelaufen");
        }

        // Account als verifiziert markieren
        accountDao.setEmailVerified(accountId);

        // Codes löschen
        emailVerificationDao.deleteByAccountId(accountId);
    }

    // ──────────────────────────────────────────
    // HILFSMETHODEN
    // ──────────────────────────────────────────

    private String generateCode() {
        return String.format("%06d", new SecureRandom().nextInt(1_000_000));
    }
}

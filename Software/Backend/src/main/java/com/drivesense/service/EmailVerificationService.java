package com.drivesense.service;
import com.drivesense.db.AccountDao;
import com.drivesense.db.EmailVerificationDao;
import com.drivesense.exceptions.BadRequestException;
import com.drivesense.exceptions.NotFoundException;
import com.drivesense.model.Account;
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

    public void verifyCode(String email, String code) {
        Account account = accountDao.getByEmail(email);
        if (account == null) throw new BadRequestException("Ungültiger Code");

        List<EmailVerification> codes = emailVerificationDao.getAllByAccountId(account.getId());

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
        accountDao.setEmailVerified(account.getId());

        // Codes löschen
        emailVerificationDao.deleteByAccountId(account.getId());
    }

    public void confirmEmailChange(int accountId, String code) {
        Account account = accountDao.getById(accountId);
        if (account == null) throw new NotFoundException("Account nicht gefunden");

        if (account.getPendingEmail() == null) {
            throw new BadRequestException("Keine ausstehende Email-Änderung");
        }

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

        // Email übernehmen
        account.setEmail(account.getPendingEmail());
        account.setPendingEmail(null);
        account.setEmailVerified(true);
        accountDao.update(account);

        emailVerificationDao.deleteByAccountId(accountId);
    }

    // ──────────────────────────────────────────
    // HILFSMETHODEN
    // ──────────────────────────────────────────

    private String generateCode() {
        return String.format("%06d", new SecureRandom().nextInt(1_000_000));
    }
}

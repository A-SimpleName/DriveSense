package com.drivesense.service;

import com.drivesense.db.AccountDao;
import com.drivesense.db.PasswordResetTokenDao;
import com.drivesense.exceptions.BadRequestException;
import com.drivesense.model.Account;
import com.drivesense.model.PasswordResetToken;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class PasswortResetService {
    @Autowired
    private PasswordResetTokenDao passwordResetTokenDao;
    @Autowired
    private AccountDao accountDao;
    @Autowired
    private EmailService emailService;

    // ──────────────────────────────────────────
    // CODE GENERIEREN + EMAIL SENDEN
    // ──────────────────────────────────────────

    public void sendResetCode(String email) {
        // Immer 200 zurückgeben – kein Email-Enumeration Angriff möglich
        Account account = accountDao.getByEmail(email);
        if (account == null) return;

        String code = generateCode();
        String codeHash = BCrypt.hashpw(code, BCrypt.gensalt());

        PasswordResetToken token = new PasswordResetToken();
        token.setAccountId(account.getId());
        token.setCodeHash(codeHash);
        token.setExpiresAt(LocalDateTime.now().plusMinutes(15));
        passwordResetTokenDao.insert(token);

        emailService.sendPasswordResetCode(email, code);
    }

    // ──────────────────────────────────────────
    // CODE PRÜFEN + PASSWORT ÄNDERN
    // ──────────────────────────────────────────

    public void resetPassword(String email, String code, String newPassword) {
        Account account = accountDao.getByEmail(email);
        if (account == null) throw new BadRequestException("Ungültiger Code");

        List<PasswordResetToken> tokens = passwordResetTokenDao.getAllValidByAccount(account.getId());

        if (tokens == null || tokens.isEmpty()) {
            throw new BadRequestException("Ungültiger oder abgelaufener Code");
        }

        PasswordResetToken valid = tokens.stream()
                .filter(t -> BCrypt.checkpw(code, t.getCodeHash()))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("Ungültiger oder abgelaufener Code"));

        // Passwort hashen + speichern
        String hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
        accountDao.updatePassword(account.getId(), hashedPassword);

        // Token als used markieren
        passwordResetTokenDao.markAsUsed(valid.getId());
    }

    // ──────────────────────────────────────────
    // HILFSMETHODEN
    // ──────────────────────────────────────────

    private String generateCode() {
        return String.format("%06d", new SecureRandom().nextInt(1_000_000));
    }
}

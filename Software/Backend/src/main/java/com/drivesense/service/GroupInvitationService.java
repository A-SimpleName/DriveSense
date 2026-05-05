package com.drivesense.service;
import com.drivesense.db.*;
import com.drivesense.exceptions.*;
import com.drivesense.model.*;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class GroupInvitationService {
    @Autowired
    private GroupInvitationDao groupInvitationDao;
    @Autowired
    private AccountDao accountDao;
    @Autowired
    private ProfileDao profileDao;
    @Autowired
    private UserGroupDao userGroupDao;
    @Autowired
    private UsergroupService usergroupService;
    @Autowired
    private EmailService emailService;

    // ──────────────────────────────────────────
    // EINLADUNG VERSCHICKEN
    // ──────────────────────────────────────────

    public void inviteToGroup(int groupId, int inviterProfileId, String email) {
        UserGroup group = userGroupDao.getById(groupId);
        if (group == null) throw new NotFoundException("Gruppe nicht gefunden");

        // Einlader ist OWNER oder ADMIN?
        if (!usergroupService.isGroupOwnerOrAdmin(groupId, inviterProfileId)) {
            throw new UnauthorizedException("Nur OWNER und ADMIN dürfen einladen");
        }

        // Account mit dieser Email finden
        Account invitedAccount = accountDao.getByEmail(email);
        if (invitedAccount == null) throw new NotFoundException("Kein Account mit dieser E-Mail gefunden");

        // Code generieren
        String code = generateCode();
        String codeHash = BCrypt.hashpw(code, BCrypt.gensalt());
        LocalDateTime expiresAt = LocalDateTime.now().plusHours(48);

        // Gibt es schon eine offene Einladung? → überschreiben
        GroupInvitation existing = groupInvitationDao.getPendingByAccountAndGroup(invitedAccount.getId(), groupId);

        if (existing != null) {
            groupInvitationDao.updateCode(existing.getId(), codeHash, expiresAt);
        } else {
            GroupInvitation invitation = new GroupInvitation();
            invitation.setGroupId(groupId);
            invitation.setInvitedAccountId(invitedAccount.getId());
            invitation.setInvitedByProfileId(inviterProfileId);
            invitation.setCodeHash(codeHash);
            invitation.setExpiresAt(expiresAt);
            groupInvitationDao.insert(invitation);
        }

        // Email senden
        Profile inviterProfile = profileDao.getById(inviterProfileId);
        if (inviterProfile == null) throw new NotFoundException("Profil nicht gefunden");

        emailService.sendGroupInvitation(
                email,
                inviterProfile.getName(),
                group.getName(),
                code
        );
    }

    // ──────────────────────────────────────────
    // CODE PRÜFEN → PROFILE ZURÜCKGEBEN
    // ──────────────────────────────────────────

    public List<Profile> verifyInviteCode(int accountId, String code) {
        GroupInvitation invitation = getValidInvitation(accountId, code);

        if (invitation.getExpiresAt().isBefore(LocalDateTime.now())) {
            groupInvitationDao.updateStatus(invitation.getId(), "EXPIRED");
            throw new BadRequestException("Einladungscode ist abgelaufen");
        }

        List<Profile> profiles = profileDao.getAllProfilesByAccountId(accountId);
        if (profiles == null || profiles.isEmpty()) {
            throw new NotFoundException("Keine Profile gefunden");
        }
        return profiles;
    }

    // ──────────────────────────────────────────
    // PROFIL AUSWÄHLEN → GRUPPE BEITRETEN
    // ──────────────────────────────────────────

    public void acceptInvite(int accountId, String code, int profileId) {
        GroupInvitation invitation = getValidInvitation(accountId, code);

        if (invitation.getExpiresAt().isBefore(LocalDateTime.now())) {
            groupInvitationDao.updateStatus(invitation.getId(), "EXPIRED");
            throw new BadRequestException("Einladungscode ist abgelaufen");
        }

        // Gehört das Profil zu diesem Account?
        Profile profile = profileDao.getById(profileId);
        if (profile == null) throw new NotFoundException("Profil nicht gefunden");
        if (profile.getAccount_id() != accountId) {
            throw new UnauthorizedException("Dieses Profil gehört nicht zu deinem Account");
        }

        usergroupService.addMember(
                invitation.getGroupId(),
                profileId,
                invitation.getInvitedByProfileId(),
                "ADMIN"
        );

        groupInvitationDao.updateStatus(invitation.getId(), "ACCEPTED");
    }


    private GroupInvitation getValidInvitation(int accountId, String code) {
        List<GroupInvitation> pending = groupInvitationDao.getAllPendingByAccount(accountId);
        if (pending == null || pending.isEmpty()) {
            throw new BadRequestException("Ungültiger oder abgelaufener Code");
        }
        return pending.stream()
                .filter(inv -> BCrypt.checkpw(code, inv.getCodeHash()))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("Ungültiger oder abgelaufener Code"));
    }

    private String generateCode() {
        return String.format("%06d", new SecureRandom().nextInt(1_000_000));
    }
}

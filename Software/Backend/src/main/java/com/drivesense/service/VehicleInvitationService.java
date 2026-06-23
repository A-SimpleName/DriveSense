package com.drivesense.service;

import com.drivesense.db.*;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.exceptions.*;
import com.drivesense.model.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class VehicleInvitationService {

    @Autowired private VehicleInvitationDao vehicleInvitationDao;
    @Autowired private VehicleDao           vehicleDao;
    @Autowired private AccountDao           accountDao;
    @Autowired private ProfileDao           profileDao;
    @Autowired private EmailService         emailService;

    // ── Einladung verschicken ────────────────────────────────────────────────

    /**
     * Ein Profil (mindestens CO_OWNER) lädt einen Account per E-Mail ein.
     * - OWNER  darf CO_OWNER und DRIVER einladen
     * - CO_OWNER darf nur DRIVER einladen
     */
    public void inviteToVehicle(int vehicleId, int inviterProfileId, String email, String role) {
        // Fahrzeug existiert und Einlader hat Zugriff?
        VehicleDto vehicle = vehicleDao.getAllVehiclesByProfile(inviterProfileId)
                .stream()
                .filter(v -> v.getId() == vehicleId)
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Fahrzeug nicht gefunden oder kein Zugriff"));

        String inviterRole = vehicle.getMyRole();

        // Nur OWNER und CO_OWNER dürfen einladen
        if (!"OWNER".equals(inviterRole) && !"CO_OWNER".equals(inviterRole)) {
            throw new UnauthorizedException("Nur OWNER und CO_OWNER dürfen einladen");
        }

        // CO_OWNER darf keine CO_OWNER erstellen – nur OWNER darf das
        if ("CO_OWNER".equals(role) && !"OWNER".equals(inviterRole)) {
            throw new UnauthorizedException("Nur OWNER darf CO_OWNER einladen");
        }

        // OWNER-Rolle darf nie per Einladung vergeben werden
        if ("OWNER".equals(role)) {
            throw new BadRequestException("Die Rolle OWNER kann nicht per Einladung vergeben werden");
        }

        // Eingeladenen Account suchen
        Account invitedAccount = accountDao.getByEmail(email);
        if (invitedAccount == null) throw new NotFoundException("Kein Account mit dieser E-Mail gefunden");

        // Sich selbst einladen verbieten
        Profile inviterProfile = profileDao.getById(inviterProfileId);
        if (inviterProfile == null) throw new NotFoundException("Einladendes Profil nicht gefunden");
        if (inviterProfile.getAccount_id() == invitedAccount.getId()) {
            throw new BadRequestException("Du kannst dich nicht selbst einladen");
        }

        // Prüfen ob der Account noch ein freies Profil hat (ohne Zugriff auf das Fahrzeug)
        List<Profile> invitedProfiles = profileDao.getAllProfilesByAccountId(invitedAccount.getId());
        boolean hasAvailableProfile = invitedProfiles.stream()
                .anyMatch(p -> !profileHasVehicle(p.getId(), vehicleId));
        if (!hasAvailableProfile) {
            throw new BadRequestException("Alle Profile dieses Accounts haben bereits Zugriff auf das Fahrzeug");
        }

        // Code generieren
        String code     = generateCode();
        String codeHash = BCrypt.hashpw(code, BCrypt.gensalt());
        LocalDateTime expiresAt = LocalDateTime.now().plusHours(48);

        // Bestehende offene Einladung überschreiben (Re-Invite)
        VehicleInvitation existing =
                vehicleInvitationDao.getPendingByAccountAndVehicle(invitedAccount.getId(), vehicleId);
        if (existing != null) {
            vehicleInvitationDao.updateCode(existing.getId(), codeHash, expiresAt);
        } else {
            VehicleInvitation invitation = new VehicleInvitation();
            invitation.setVehicleId(vehicleId);
            invitation.setInvitedAccountId(invitedAccount.getId());
            invitation.setInvitedByProfileId(inviterProfileId);
            invitation.setCodeHash(codeHash);
            invitation.setRole(role);
            invitation.setExpiresAt(expiresAt);
            vehicleInvitationDao.insert(invitation);
        }

        emailService.sendVehicleInvitation(
                email,
                inviterProfile.getName(),
                vehicle.getModel() + " (" + vehicle.getLicensePlate() + ")",
                role,
                code
        );
    }

    // ── Code annehmen (automatisch erstes freies Profil) ────────────────────

    /**
     * Nimmt eine Einladung an – analog zum Group-Flow ohne manuelle Profilauswahl.
     * Es wird automatisch das erste Profil des Accounts gewählt, das noch keinen
     * Zugriff auf das Fahrzeug hat.
     */
    public void acceptInviteAuto(int accountId, String code) {
        VehicleInvitation invitation = getValidInvitation(accountId, code);

        List<Profile> profiles = profileDao.getAllProfilesByAccountId(accountId);
        Profile targetProfile = profiles.stream()
                .filter(p -> !profileHasVehicle(p.getId(), invitation.getVehicleId()))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("Alle deine Profile haben bereits Zugriff auf das Fahrzeug"));

        vehicleDao.addProfileAssociation(invitation.getVehicleId(), targetProfile.getId(), invitation.getRole());
        vehicleInvitationDao.updateStatus(invitation.getId(), "ACCEPTED");
    }

    // ── Code prüfen → Profile zurückgeben (für erweiterte Flows, falls nötig) ──

    public List<Profile> verifyInviteCode(int accountId, String code) {
        VehicleInvitation invitation = getValidInvitation(accountId, code);

        List<Profile> profiles = profileDao.getAllProfilesByAccountId(accountId);
        if (profiles == null || profiles.isEmpty()) throw new NotFoundException("Keine Profile gefunden");

        return profiles.stream()
                .filter(p -> !profileHasVehicle(p.getId(), invitation.getVehicleId()))
                .collect(Collectors.toList());
    }

    // ── Profil wählen → Fahrzeug beitreten (für erweiterte Flows, falls nötig) ─

    public void acceptInvite(int accountId, String code, int profileId) {
        VehicleInvitation invitation = getValidInvitation(accountId, code);

        Profile profile = profileDao.getById(profileId);
        if (profile == null) throw new NotFoundException("Profil nicht gefunden");
        if (profile.getAccount_id() != accountId) {
            throw new UnauthorizedException("Dieses Profil gehört nicht zu deinem Account");
        }

        List<VehicleDto> existing = vehicleDao.getAllVehiclesByProfile(profileId);
        boolean alreadyLinked = existing.stream().anyMatch(v -> v.getId() == invitation.getVehicleId());
        if (alreadyLinked) {
            throw new BadRequestException("Dieses Profil hat bereits Zugriff auf das Fahrzeug");
        }

        vehicleDao.addProfileAssociation(invitation.getVehicleId(), profileId, invitation.getRole());
        vehicleInvitationDao.updateStatus(invitation.getId(), "ACCEPTED");
    }

    // ── Einladungslink (E-Mail-Link-Flow) ────────────────────────────────────

    public VehicleDto acceptInviteLink(String code) {
        VehicleInvitation invitation = getValidInvitationByCode(code);

        Account invitedAccount = accountDao.getById(invitation.getInvitedAccountId());
        if (invitedAccount == null) {
            throw new NotFoundException("Eingeladener Account nicht gefunden");
        }

        List<Profile> profiles = profileDao.getAllProfilesByAccountId(invitedAccount.getId());
        Profile targetProfile = profiles.stream()
                .filter(p -> !profileHasVehicle(p.getId(), invitation.getVehicleId()))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("Alle Profile dieses Accounts haben bereits Zugriff auf das Fahrzeug"));

        vehicleDao.addProfileAssociation(invitation.getVehicleId(), targetProfile.getId(), invitation.getRole());
        vehicleInvitationDao.updateStatus(invitation.getId(), "ACCEPTED");

        return vehicleDao.getById(invitation.getVehicleId(), invitedAccount.getId());
    }

    // ── Interne Hilfsmethoden ────────────────────────────────────────────────

    private VehicleInvitation getValidInvitation(int accountId, String code) {
        List<VehicleInvitation> pending = vehicleInvitationDao.getAllPendingByAccount(accountId);
        if (pending == null || pending.isEmpty()) {
            throw new BadRequestException("Ungültiger oder abgelaufener Code");
        }

        VehicleInvitation invitation = pending.stream()
                .filter(inv -> BCrypt.checkpw(code, inv.getCodeHash()))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("Ungültiger oder abgelaufener Code"));

        if (invitation.getExpiresAt().isBefore(LocalDateTime.now())) {
            vehicleInvitationDao.updateStatus(invitation.getId(), "EXPIRED");
            throw new BadRequestException("Einladungscode ist abgelaufen");
        }

        return invitation;
    }

    private VehicleInvitation getValidInvitationByCode(String code) {
        List<VehicleInvitation> pending = vehicleInvitationDao.getAllPending();
        if (pending == null || pending.isEmpty()) {
            throw new BadRequestException("Ungültiger oder abgelaufener Einladungslink");
        }

        VehicleInvitation invitation = pending.stream()
                .filter(inv -> BCrypt.checkpw(code, inv.getCodeHash()))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("Ungültiger oder abgelaufener Einladungslink"));

        if (invitation.getExpiresAt().isBefore(LocalDateTime.now())) {
            vehicleInvitationDao.updateStatus(invitation.getId(), "EXPIRED");
            throw new BadRequestException("Einladungslink ist abgelaufen");
        }

        return invitation;
    }

    private boolean profileHasVehicle(int profileId, int vehicleId) {
        return vehicleDao.getAllVehiclesByProfile(profileId)
                .stream()
                .anyMatch(v -> v.getId() == vehicleId);
    }

    private String generateCode() {
        return String.format("%06d", new SecureRandom().nextInt(1_000_000));
    }
}
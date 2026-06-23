package com.drivesense.controller;

import com.drivesense.dto.request.*;
import com.drivesense.dto.response.ProfileSelectionResponse;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.dto.response.VehicleMemberResponse;
import com.drivesense.exceptions.UnauthorizedException;
import com.drivesense.model.Profile;
import com.drivesense.model.Vehicle;
import com.drivesense.service.VehicleInvitationService;
import com.drivesense.service.VehicleService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/vehicles")
public class VehicleController {

    @Autowired private VehicleService vehicleService;
    @Autowired private VehicleInvitationService vehicleInvitationService;

    // ── Fahrzeuge ────────────────────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<List<VehicleDto>> getAllVehiclesByProfile(HttpServletRequest request) {
        Object profileIdAttribute = request.getAttribute("profileId");
        if (!(profileIdAttribute instanceof Integer profileId)) {
            throw new UnauthorizedException("Kein aktives Profil ausgewählt");
        }
        return ResponseEntity.ok(vehicleService.getAllVehiclesByProfile(profileId));
    }

    @GetMapping("/account")
    public ResponseEntity<List<VehicleDto>> getAllVehiclesByAccount(HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        return ResponseEntity.ok(vehicleService.getAllVehiclesByAccount(accountId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<VehicleDto> getVehicle(@PathVariable int id, HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        return ResponseEntity.ok(vehicleService.getVehicleById(id, accountId));
    }

    @PostMapping
    public ResponseEntity<Vehicle> saveVehicle(
            @Valid @RequestBody SaveVehicleRequest req,
            HttpServletRequest request) {

        Object profileIdAttribute = request.getAttribute("profileId");
        if (!(profileIdAttribute instanceof Integer profileId)) {
            throw new UnauthorizedException("Kein aktives Profil ausgewählt");
        }
        Vehicle v = new Vehicle();
        v.setModel(req.getModel());
        v.setLicensePlate(req.getLicensePlate());
        v.setMileage(req.getMileage());
        return ResponseEntity.status(201).body(vehicleService.saveVehicle(v, profileId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Void> update(
            @PathVariable int id,
            @RequestBody Vehicle vehicle,
            HttpServletRequest request) {

        int accountId = (int) request.getAttribute("accountId");
        vehicle.setId(id);
        vehicleService.updateVehicle(vehicle, accountId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable int id, HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        Object profileIdAttribute = request.getAttribute("profileId");
        if (!(profileIdAttribute instanceof Integer profileId)) {
            throw new UnauthorizedException("Kein aktives Profil ausgewählt");
        }
        vehicleService.deleteVehicle(id, accountId, profileId);
        return ResponseEntity.noContent().build();
    }

    // ── Mitglieder ───────────────────────────────────────────────────────────

    /**
     * GET /api/vehicles/{id}/members
     * Gibt alle Mitglieder zurück. Nur OWNER und CO_OWNER dürfen das aufrufen.
     */
    @GetMapping("/{id}/members")
    public ResponseEntity<List<VehicleMemberResponse>> getVehicleMembers(
            @PathVariable int id,
            HttpServletRequest request) {

        Object profileIdAttribute = request.getAttribute("profileId");
        if (!(profileIdAttribute instanceof Integer profileId)) {
            throw new UnauthorizedException("Kein aktives Profil ausgewaehlt");
        }
        return ResponseEntity.ok(vehicleService.getVehicleMembers(id, profileId));
    }

    /**
     * DELETE /api/vehicles/{vehicleId}/members/{profileId}
     * OWNER entfernt CO_OWNER oder DRIVER.
     * CO_OWNER entfernt nur DRIVER.
     * Niemand kann den OWNER entfernen. OWNER kann sich nicht selbst entfernen.
     */
    @DeleteMapping("/{vehicleId}/members/{targetProfileId}")
    public ResponseEntity<Void> removeMember(
            @PathVariable int vehicleId,
            @PathVariable int targetProfileId,
            HttpServletRequest request) {

        Object profileIdAttribute = request.getAttribute("profileId");
        if (!(profileIdAttribute instanceof Integer requesterProfileId)) {
            throw new UnauthorizedException("Kein aktives Profil ausgewählt");
        }
        vehicleService.removeMember(vehicleId, requesterProfileId, targetProfileId);
        return ResponseEntity.noContent().build();
    }

    // ── Einladungen ──────────────────────────────────────────────────────────

    /**
     * GET /api/vehicles/invitations/accept-link?code=...
     * Einladungslink aus der E-Mail – öffnet sich im Browser, kein Login nötig.
     */
    @GetMapping(value = "/invitations/accept-link", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> acceptInviteLink(@RequestParam String code) {
        VehicleDto vehicle = vehicleInvitationService.acceptInviteLink(code);
        String vehicleName = escapeHtml(vehicle.getModel() + " (" + vehicle.getLicensePlate() + ")");
        return ResponseEntity.ok("""
                <!doctype html>
                <html lang="de">
                <head>
                  <meta charset="utf-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1">
                  <title>DriveSense Einladung angenommen</title>
                </head>
                <body style="font-family:Arial,sans-serif;margin:40px;line-height:1.5">
                  <h1>Einladung angenommen</h1>
                  <p>Du hast jetzt Zugriff auf das Fahrzeug <strong>%s</strong>.</p>
                  <p>Du kannst DriveSense nun wieder oeffnen.</p>
                </body>
                </html>
                """.formatted(vehicleName));
    }

    /**
     * POST /api/vehicles/{vehicleId}/invitations
     * OWNER / CO_OWNER lädt einen Account per E-Mail ein.
     * - OWNER kann CO_OWNER oder DRIVER einladen
     * - CO_OWNER kann nur DRIVER einladen (wird im Service geprüft)
     */
    @PostMapping("/{vehicleId}/invitations")
    public ResponseEntity<Void> inviteToVehicle(
            @PathVariable int vehicleId,
            @RequestBody @Valid InviteToVehicleRequest request,
            HttpServletRequest httpRequest) {

        Object profileIdAttr = httpRequest.getAttribute("profileId");
        if (!(profileIdAttr instanceof Integer profileId)) {
            throw new UnauthorizedException("Kein aktives Profil ausgewählt");
        }
        vehicleInvitationService.inviteToVehicle(vehicleId, profileId, request.getEmail(), request.getRole());
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/vehicles/invitations/accept
     * Einladung annehmen – nur Code nötig, Profil wird automatisch gewählt.
     */
    @PostMapping("/invitations/accept")
    public ResponseEntity<Void> acceptInviteAuto(
            @RequestBody @Valid VerifyInviteRequest request,
            HttpServletRequest httpRequest) {

        int accountId = (int) httpRequest.getAttribute("accountId");
        vehicleInvitationService.acceptInviteAuto(accountId, request.getCode());
        return ResponseEntity.ok().build();
    }

    // ── Legacy-Endpoints (vehicle-scoped) ────────────────────────────────────

    @PostMapping("/{vehicleId}/invitations/verify")
    public ResponseEntity<List<ProfileSelectionResponse>> verifyInvite(
            @PathVariable int vehicleId,
            @RequestBody @Valid VerifyInviteRequest request,
            HttpServletRequest httpRequest) {

        int accountId = (int) httpRequest.getAttribute("accountId");
        List<Profile> profiles = vehicleInvitationService.verifyInviteCode(accountId, request.getCode());
        List<ProfileSelectionResponse> response = profiles.stream()
                .map(p -> new ProfileSelectionResponse(p.getId(), p.getName(), p.getRole()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{vehicleId}/invitations/accept")
    public ResponseEntity<Void> acceptInvite(
            @PathVariable int vehicleId,
            @RequestBody @Valid AcceptInviteRequest request,
            HttpServletRequest httpRequest) {

        int accountId = (int) httpRequest.getAttribute("accountId");
        vehicleInvitationService.acceptInvite(accountId, request.getCode(), request.getProfileId());
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{vehicleId}/members/{profileId}/role")
    public ResponseEntity<Void> updateMemberRole(
            @PathVariable int vehicleId,
            @PathVariable int profileId,
            @RequestBody UpdateMemberRoleRequest body,
            HttpServletRequest request) {

        Object profileIdAttribute = request.getAttribute("profileId");
        if (!(profileIdAttribute instanceof Integer requesterProfileId)) {
            throw new UnauthorizedException("Kein aktives Profil ausgewaehlt");
        }

        vehicleService.updateMemberRole(vehicleId, requesterProfileId, profileId, body.getRole());

        return ResponseEntity.noContent().build();
    }

    // ── Hilfsmethoden ────────────────────────────────────────────────────────

    private String escapeHtml(String value) {
        return value == null ? "" : value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}

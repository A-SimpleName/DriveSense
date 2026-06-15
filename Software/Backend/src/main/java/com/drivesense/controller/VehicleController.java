package com.drivesense.controller;

import com.drivesense.dto.request.AcceptInviteRequest;
import com.drivesense.dto.request.InviteToVehicleRequest;
import com.drivesense.dto.request.SaveVehicleRequest;
import com.drivesense.dto.request.VerifyInviteRequest;
import com.drivesense.dto.response.ProfileSelectionResponse;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.exceptions.UnauthorizedException;
import com.drivesense.model.Profile;
import com.drivesense.model.Vehicle;
import com.drivesense.service.VehicleInvitationService;
import com.drivesense.service.VehicleService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
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

    // ── Einladungen ──────────────────────────────────────────────────────────

    /**
     * POST /api/vehicles/{vehicleId}/invitations
     * OWNER / CO_OWNER lädt einen Account per E-Mail ein.
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
     * POST /api/vehicles/{vehicleId}/invitations/verify
     * Code prüfen → verfügbare Profile des eingeladenen Accounts zurückgeben.
     */
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

    /**
     * POST /api/vehicles/{vehicleId}/invitations/accept
     * Einladung annehmen: Code + gewähltes Profil übergeben.
     */
    @PostMapping("/{vehicleId}/invitations/accept")
    public ResponseEntity<Void> acceptInvite(
            @PathVariable int vehicleId,
            @RequestBody @Valid AcceptInviteRequest request,
            HttpServletRequest httpRequest) {

        int accountId = (int) httpRequest.getAttribute("accountId");
        vehicleInvitationService.acceptInvite(accountId, request.getCode(), request.getProfileId());
        return ResponseEntity.ok().build();
    }
}
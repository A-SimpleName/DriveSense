package com.drivesense.service;

import com.drivesense.db.VehicleDao;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.dto.response.VehicleMemberResponse;
import com.drivesense.exceptions.BadRequestException;
import com.drivesense.exceptions.NotFoundException;
import com.drivesense.exceptions.UnauthorizedException;
import com.drivesense.model.Vehicle;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class VehicleService {

    @Autowired
    private VehicleDao vehicleDao;

    public List<VehicleDto> getAllVehiclesByAccount(int accountId) {
        return vehicleDao.getAllVehiclesByAccount(accountId);
    }

    public List<VehicleDto> getAllVehiclesByProfile(int profileId) {
        return vehicleDao.getAllVehiclesByProfile(profileId);
    }

    public VehicleDto getVehicleById(int id, int accountId) {
        VehicleDto vehicle = vehicleDao.getById(id, accountId);
        if (vehicle == null) throw new NotFoundException("Vehicle nicht gefunden oder kein Zugriff");
        return vehicle;
    }

    public List<VehicleMemberResponse> getVehicleMembers(int vehicleId, int requesterProfileId) {
        VehicleDto vehicle = vehicleDao.getAllVehiclesByProfile(requesterProfileId)
                .stream()
                .filter(v -> v.getId() == vehicleId)
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Vehicle nicht gefunden oder kein Zugriff"));

        String role = vehicle.getMyRole();
        if (!"OWNER".equals(role) && !"CO_OWNER".equals(role)) {
            throw new UnauthorizedException("Nur Owner und Co-Owner duerfen Fahrzeug-Freigaben sehen");
        }

        return vehicleDao.getMembersByVehicleId(vehicleId);
    }

    public Vehicle saveVehicle(Vehicle vehicle, int profileId) {
        return vehicleDao.insert(vehicle, profileId);
    }

    public void updateVehicle(Vehicle vehicle, int accountId) {
        vehicleDao.update(vehicle, accountId);
    }

    /**
     * Löscht ein Vehicle oder entfernt eine Profilverknüpfung, je nach Rolle:
     * - OWNER: Soft-Delete des gesamten Vehicles – keine Rollenweiterleitung.
     * - CO_OWNER / DRIVER: Nur die eigene profile_vehicle-Verknüpfung wird entfernt.
     * OWNER kann sich selbst nicht über diesen Weg entfernen (nur soft-delete des Vehicles).
     */
    public void deleteVehicle(int vehicleId, int accountId, int profileId) {
        boolean softDeleted = vehicleDao.softDelete(vehicleId, accountId);
        if (!softDeleted) {
            boolean removed = vehicleDao.removeProfileAssociation(vehicleId, profileId, accountId);
            if (!removed) {
                throw new NotFoundException("Vehicle nicht gefunden oder kein Zugriff");
            }
        }
    }

    /**
     * OWNER befördert/degradiert ein Mitglied zwischen DRIVER und CO_OWNER.
     *
     * Regeln:
     * - Nur OWNER darf Rollen ändern
     * - OWNER kann sich selbst nicht umbenennen
     * - Der OWNER selbst kann nicht zum Ziel einer Rollenänderung werden
     * - Erlaubte Zielrollen sind ausschließlich CO_OWNER und DRIVER
     *
     * @param vehicleId          ID des Fahrzeugs
     * @param requesterProfileId Profil des Anfragenden (muss OWNER sein)
     * @param targetProfileId    Profil dessen Rolle geändert werden soll
     * @param newRole            neue Rolle (CO_OWNER oder DRIVER)
     */
    public void updateMemberRole(int vehicleId, int requesterProfileId, int targetProfileId, String newRole) {
        // Eigene Rolle des Anfragers laden
        VehicleDto vehicle = vehicleDao.getAllVehiclesByProfile(requesterProfileId)
                .stream()
                .filter(v -> v.getId() == vehicleId)
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Vehicle nicht gefunden oder kein Zugriff"));

        String requesterRole = vehicle.getMyRole();

        if (!"OWNER".equals(requesterRole)) {
            throw new UnauthorizedException("Nur OWNER darf Mitgliedsrollen ändern");
        }

        // Sich selbst umbenennen ist über diesen Endpoint nicht erlaubt
        if (requesterProfileId == targetProfileId) {
            throw new BadRequestException("Du kannst deine eigene Rolle nicht über diesen Weg ändern");
        }

        // Nur CO_OWNER und DRIVER sind gültige Zielrollen
        if (!"CO_OWNER".equals(newRole) && !"DRIVER".equals(newRole)) {
            throw new BadRequestException("Ungültige Zielrolle");
        }

        // Rolle des Zielprofils laden
        List<VehicleMemberResponse> members = vehicleDao.getMembersByVehicleId(vehicleId);
        VehicleMemberResponse target = members.stream()
                .filter(m -> m.getProfileId() == targetProfileId)
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Mitglied nicht gefunden"));

        // OWNER kann nie zum Ziel einer Rollenänderung werden
        if ("OWNER".equals(target.getVehicleRole())) {
            throw new BadRequestException("Der OWNER des Fahrzeugs kann nicht umbenannt werden");
        }

        boolean updated = vehicleDao.updateMemberRole(vehicleId, targetProfileId, newRole);
        if (!updated) {
            throw new NotFoundException("Rolle konnte nicht geändert werden");
        }
    }

    /**
     * OWNER oder CO_OWNER wirft ein anderes Mitglied raus.
     *
     * Regeln:
     * - OWNER   kann CO_OWNER und DRIVER entfernen, aber nicht sich selbst
     * - CO_OWNER kann nur DRIVER entfernen
     * - Niemand kann den OWNER entfernen
     *
     * @param vehicleId          ID des Fahrzeugs
     * @param requesterProfileId Profil des Anfragenden (muss OWNER oder CO_OWNER sein)
     * @param targetProfileId    Profil das entfernt werden soll
     */
    public void removeMember(int vehicleId, int requesterProfileId, int targetProfileId) {
        // Eigene Rolle des Anfragers laden
        VehicleDto vehicle = vehicleDao.getAllVehiclesByProfile(requesterProfileId)
                .stream()
                .filter(v -> v.getId() == vehicleId)
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Vehicle nicht gefunden oder kein Zugriff"));

        String requesterRole = vehicle.getMyRole();

        if (!"OWNER".equals(requesterRole) && !"CO_OWNER".equals(requesterRole)) {
            throw new UnauthorizedException("Nur OWNER und CO_OWNER dürfen Mitglieder entfernen");
        }

        // Sich selbst entfernen ist über diesen Endpoint nicht erlaubt
        if (requesterProfileId == targetProfileId) {
            throw new BadRequestException("Du kannst dich selbst nicht über diesen Weg entfernen");
        }

        // Rolle des Zielprofils laden
        List<VehicleMemberResponse> members = vehicleDao.getMembersByVehicleId(vehicleId);
        VehicleMemberResponse target = members.stream()
                .filter(m -> m.getProfileId() == targetProfileId)
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Mitglied nicht gefunden"));

        String targetRole = target.getVehicleRole();

        // OWNER kann nie entfernt werden
        if ("OWNER".equals(targetRole)) {
            throw new BadRequestException("Der OWNER des Fahrzeugs kann nicht entfernt werden");
        }

        // CO_OWNER darf nur DRIVER entfernen
        if ("CO_OWNER".equals(requesterRole) && !"DRIVER".equals(targetRole)) {
            throw new UnauthorizedException("CO_OWNER darf nur DRIVER entfernen");
        }

        boolean removed = vehicleDao.removeMemberAssociation(vehicleId, targetProfileId);
        if (!removed) {
            throw new NotFoundException("Mitglied konnte nicht entfernt werden");
        }
    }

    public List<VehicleDto> getAllVehicles() {
        return vehicleDao.getAllVehicles();
    }
}
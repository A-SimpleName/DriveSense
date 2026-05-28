package com.drivesense.service;

import com.drivesense.db.VehicleDao;
import com.drivesense.dto.response.VehicleDto;
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

    public Vehicle saveVehicle(Vehicle vehicle, int profileId) {
        return vehicleDao.insert(vehicle, profileId);
    }

    public void updateVehicle(Vehicle vehicle, int accountId) {
        vehicleDao.update(vehicle, accountId);
    }

    /**
     * Löscht ein Vehicle oder entfernt eine Profilverknüpfung, je nach Rolle:
     * - OWNER: Soft-Delete des gesamten Vehicles (deleted_at setzen).
     *   Existierende Trips bleiben durch Snapshots erhalten.
     * - CO_OWNER / DRIVER: Nur die profile_vehicle-Verknüpfung wird entfernt.
     *
     * Die Unterscheidung passiert im DAO: softDelete prüft per JOIN ob der
     * Account OWNER ist; removeProfileAssociation entfernt nur den Eintrag.
     */
    public void deleteVehicle(int vehicleId, int accountId, int profileId) {
        // Zuerst versuchen, als OWNER soft zu löschen
        boolean softDeleted = vehicleDao.softDelete(vehicleId, accountId);
        if (!softDeleted) {
            // Kein OWNER → Verknüpfung als CO_OWNER / DRIVER entfernen
            boolean removed = vehicleDao.removeProfileAssociation(vehicleId, profileId, accountId);
            if (!removed) {
                throw new NotFoundException("Vehicle nicht gefunden oder kein Zugriff");
            }
        }
    }

    public List<VehicleDto> getAllVehicles() {
        return vehicleDao.getAllVehicles();
    }
}

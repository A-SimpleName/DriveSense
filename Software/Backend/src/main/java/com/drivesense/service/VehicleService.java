package com.drivesense.service;

import com.drivesense.db.ProfileDao;
import com.drivesense.db.VehicleDao;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.exceptions.NotFoundException;
import com.drivesense.exceptions.UnauthorizedException;
import com.drivesense.model.Profile;
import com.drivesense.model.Vehicle;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class VehicleService {

    @Autowired
    private VehicleDao vehicleDao;

    @Autowired
    private ProfileDao profileDao;

    public List<VehicleDto> getAllVehicles() {
        return vehicleDao.getAllVehicles();
    }

    public List<VehicleDto> getAllVehiclesByAccount(int accountId) {
        return vehicleDao.getAllVehiclesByAccount(accountId);
    }

    public Vehicle getVehicleById(int id, int accountId) {
        Vehicle vehicle = vehicleDao.getById(id);
        if (vehicle == null) {
            throw new NotFoundException("Fahrzeug nicht gefunden");
        }
        checkAccountOwnership(vehicle.getProfileId(), accountId);
        return vehicle;
    }

    public Vehicle saveVehicle(Vehicle vehicle) {
        Vehicle saved = vehicleDao.insert(vehicle);
        if (saved == null) {
            throw new RuntimeException("Fehler beim Speichern des Fahrzeugs");
        }
        return saved;
    }

    public void updateVehicle(Vehicle vehicle, int accountId) {
        Vehicle existing = vehicleDao.getById(vehicle.getId());
        if (existing == null) {
            throw new NotFoundException("Fahrzeug nicht gefunden");
        }
        checkAccountOwnership(existing.getProfileId(), accountId);
        vehicleDao.update(vehicle);
    }

    public void deleteVehicle(int id, int accountId) {
        Vehicle existing = vehicleDao.getById(id);
        if (existing == null) {
            throw new NotFoundException("Fahrzeug nicht gefunden");
        }
        checkAccountOwnership(existing.getProfileId(), accountId);
        vehicleDao.deleteById(id);
    }

    // Prüft ob das Profil (profileId des Fahrzeugs) zu einem der Profile des Accounts gehört.
    // So können alle Profile eines Accounts alle ihre Fahrzeuge sehen/bearbeiten.
    private void checkAccountOwnership(int vehicleProfileId, int accountId) {
        List<Profile> accountProfiles = profileDao.getAllProfilesByAccountId(accountId);
        boolean belongs = accountProfiles.stream()
                .anyMatch(p -> p.getId() == vehicleProfileId);
        if (!belongs) {
            throw new UnauthorizedException("Kein Zugriff auf dieses Fahrzeug");
        }
    }
}
package com.drivesense.service;

import com.drivesense.db.VehicleDao;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.exceptions.DatabaseException;
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

    public List<VehicleDto> getAllVehicles() {
        return vehicleDao.getAllVehicles();
    }

    public List<VehicleDto> getAllVehiclesByAccount(int accountId) {
        return vehicleDao.getAllVehiclesByAccount(accountId);
    }

    public Vehicle getVehicleById(int id, int profileId) {
        Vehicle vehicle = vehicleDao.getById(id);
        if (vehicle == null) {
            throw new NotFoundException("Fahrzeug nicht gefunden");
        }
        checkProfileAccess(profileId, id);
        return vehicle;
    }

    public Vehicle saveVehicle(Vehicle vehicle) {
        Vehicle saved = vehicleDao.insert(vehicle);
        if (saved == null) {
            throw new DatabaseException("Fehler beim Speichern des Fahrzeugs", null);
        }
        return saved;
    }

    public void updateVehicle(Vehicle vehicle, int profileId) {
        Vehicle existing = vehicleDao.getById(vehicle.getId());
        if (existing == null) {
            throw new NotFoundException("Fahrzeug nicht gefunden");
        }
        checkProfileAccess(profileId, vehicle.getId());
        vehicleDao.update(vehicle);
    }

    public void deleteVehicle(int id, int profileId) {
        Vehicle existing = vehicleDao.getById(id);
        if (existing == null) {
            throw new NotFoundException("Fahrzeug nicht gefunden");
        }
        checkProfileAccess(profileId, id);
        vehicleDao.deleteById(id);
    }

    private void checkProfileAccess(int profileId, int vehicleId) {
        if (!vehicleDao.isAssignedToProfile(profileId, vehicleId)) {
            throw new UnauthorizedException("Kein Zugriff auf dieses Fahrzeug");
        }
    }
}

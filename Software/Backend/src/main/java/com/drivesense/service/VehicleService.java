package com.drivesense.service;

import com.drivesense.db.VehicleDao;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.model.Vehicle;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class VehicleService {

   @Autowired
   private VehicleDao vehicleDao;

    public List<VehicleDto> getAllVehicles() {
        return vehicleDao.getAllVehiclesByAccount();
    }

    public Vehicle getVehicleById(int id, int profileId) {
        Vehicle vehicle = vehicleDao.getById(id);
        if (vehicle == null) {
            throw new NotFoundException("Fahrzeug nicht gefunden");
        }

        if (vehicle.getProfileId() != profileId) {
            throw new UnauthorizedException("Kein Zugriff auf dieses Fahrzeug");
        }
        return vehicle;
    }

    public Vehicle saveVehicle(Vehicle vehicle) {
        Vehicle saved = vehicleDao.insert(vehicle);
        if (saved == null) {
            throw new RuntimeException("Fehler beim Speichern des Fahrzeugs");
        }
        return saved;
    }

    public void updateVehicle(Vehicle vehicle, int profileId) {
        Vehicle existing = vehicleDao.getById(vehicle.getId());
        if (existing == null) {
            throw new NotFoundException("Fahrzeug nicht gefunden");
        }
        if (existing.getProfileId() != profileId) {
            throw new UnauthorizedException("Kein Zugriff auf dieses Fahrzeug");
        }
        vehicleDao.update(vehicle);
    }

    public void deleteVehicle(int id, int profileId) {
        Vehicle existing = vehicleDao.getById(id);
        if (existing == null) {
            throw new NotFoundException("Fahrzeug nicht gefunden");
        }
        if (existing.getProfileId() != profileId) {
            throw new UnauthorizedException("Kein Zugriff auf dieses Fahrzeug");
        }
        vehicleDao.deleteById(id);
    }
}
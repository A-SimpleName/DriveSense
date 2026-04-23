package com.drivesense.service;

import com.drivesense.db.VehicleDao;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.exceptions.NotFoundException;
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
        Vehicle vehicle = vehicleDao.getById(id, profileId);

        if (vehicle == null) {
            throw new NotFoundException("Fahrzeug nicht gefunden oder kein Zugriff");
        }

        return vehicle;
    }

    public Vehicle saveVehicle(Vehicle vehicle, int profileId) {
        return vehicleDao.insert(vehicle, profileId);
    }

    public void updateVehicle(Vehicle vehicle, int profileId) {
        vehicleDao.update(vehicle, profileId);
    }

    public void deleteVehicle(int id, int accountId) {
        vehicleDao.deleteById(id, accountId);
    }
}
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

    public List<VehicleDto> getAllVehiclesByAccount(int accountId) {
        return vehicleDao.getAllVehiclesByAccount(accountId);
    }

    public List<VehicleDto> getAllVehiclesByProfile(int profileId) {
        return vehicleDao.getAllVehiclesByProfile(profileId);
    }

    public VehicleDto getVehicleById(int id, int accountId) {
        VehicleDto vehicle = vehicleDao.getById(id, accountId);

        if (vehicle == null) {
            throw new NotFoundException("Vehicle nicht gefunden oder kein Zugriff");
        }
        return vehicle;
    }

    public Vehicle saveVehicle(Vehicle vehicle, int profileId) {
        return vehicleDao.insert(vehicle, profileId);
    }

    public void updateVehicle(Vehicle vehicle, int accountId) {
        vehicleDao.update(vehicle, accountId);
    }

    public void deleteVehicle(int id, int accountId) {
        vehicleDao.deleteById(id, accountId);
    }

    public List<VehicleDto> getAllVehicles() {
        return vehicleDao.getAllVehicles();
    }
}

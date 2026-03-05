package com.drivesense.service;

import com.drivesense.db.VehicleDao;
import com.drivesense.dto.VehicleDto;
import com.drivesense.model.Vehicle;

import java.util.List;

public class VehicleService {

    public List<VehicleDto> getAllVehicles() {
        return VehicleDao.findAllVehiclesByAccount();
    }

    public Vehicle getVehicleById(int id) {
        return VehicleDao.findById(id);
    }

    public void saveVehicle(Vehicle vehicle) {
        VehicleDao.insertVehicle(vehicle);
    }

    public void updateVehicle(Vehicle vehicle) {
        VehicleDao.update(vehicle);
    }

    public void deleteVehicle(int id) {
        VehicleDao.deleteById(id);
    }
}
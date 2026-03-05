package com.drivesense.service;

import com.drivesense.db.VehicleDao;
import com.drivesense.dto.VehicleDto;
import com.drivesense.model.Vehicle;

import java.util.List;

public class VehicleService {
    private VehicleDao vehicleDao;

    public VehicleService(VehicleDao vehicleDao) {
        this.vehicleDao = vehicleDao;
    }

    public VehicleService() {
        this.vehicleDao = new VehicleDao();
    }

    public List<VehicleDto> getAllVehicles() {
        return vehicleDao.findAllVehiclesByAccount();
    }

    public Vehicle getVehicleById(int id) {
        return vehicleDao.findById(id);
    }

    public void saveVehicle(Vehicle vehicle) {
        vehicleDao.insertVehicle(vehicle);
    }

    public void updateVehicle(Vehicle vehicle) {
        vehicleDao.update(vehicle);
    }

    public void deleteVehicle(int id) {
        vehicleDao.deleteById(id);
    }
}
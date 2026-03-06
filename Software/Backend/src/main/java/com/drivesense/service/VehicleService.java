package com.drivesense.service;

import com.drivesense.db.VehicleDao;
import com.drivesense.dto.VehicleDto;
import com.drivesense.model.Vehicle;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class VehicleService {

   @Autowired
   private VehicleDao vehicleDao;

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
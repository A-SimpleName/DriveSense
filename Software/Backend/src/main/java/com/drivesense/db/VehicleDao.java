package com.drivesense.db;

import com.drivesense.App;
import com.drivesense.dto.VehicleDto;
import com.drivesense.model.Vehicle;


import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class VehicleDao {
    public static List<VehicleDto> findAllVehiclesByAccount() {
        String sql = "SELECT v.id, v.model, u.name, v.licenseplate, v.mileage " +
                "FROM vehicle v " +
                "JOIN user u ON v.user_id = u.id";
        try (Connection conn = App.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)){
            ResultSet rs = ps.executeQuery();
            List<VehicleDto> vehicleDtos = new ArrayList<>();
            while (rs.next()) {
                vehicleDtos.add(mapDto(rs));
            }
            return vehicleDtos;
        }
        catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }
    public static void insertVehicle(Vehicle vehicle) {
        String sql = "INSERT INTO vehicle (user_id, model, licenseplate, mileage) VALUES (?,?,?,?)";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,vehicle.getUserId());
            ps.setString(2,vehicle.getModel());
            ps.setString(3,vehicle.getLicenseplate());
            ps.setInt(4,vehicle.getMileage());

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                vehicle.setId(rs.getInt(1));
            }
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static Vehicle findById(int id) {
        String sql = "SELECT * FROM vehicle WHERE id = ?";

        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return map(rs);
            }

            return null;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public static List<Vehicle> findAll () {
        String sql = "SELECT * FROM vehicle";

        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<Vehicle> vehicles = new ArrayList<>();
            while (rs.next()) {
                vehicles.add(map(rs));
            }
            return vehicles;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public static void update(Vehicle vehicle) {
        String sql = "UPDATE vehicle SET model = ?, licenseplate = ?, mileage = ? WHERE id = ?";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, vehicle.getModel());
            ps.setString(2, vehicle.getLicenseplate());
            ps.setInt(3, vehicle.getMileage());
            ps.setInt(4,vehicle.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static void deleteById(int id) {
        String sql = "DELETE FROM vehicle WHERE id = ?";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static Vehicle map(ResultSet rs) throws SQLException {
        Vehicle vehicle = new Vehicle();
        vehicle.setId(rs.getInt("id"));
        vehicle.setUserId(rs.getInt("user_id"));
        vehicle.setModel(rs.getString("model"));
        vehicle.setLicenseplate(rs.getString("licenseplate"));
        vehicle.setMileage(rs.getInt("mileage"));
        return vehicle;
    }

    public static VehicleDto mapDto(ResultSet rs) throws SQLException {
        VehicleDto vehicleDto = new VehicleDto();
        vehicleDto.setId(rs.getInt("id"));
        vehicleDto.setUserName(rs.getString("name"));
        vehicleDto.setModel(rs.getString("model"));
        vehicleDto.setLicencePlate(rs.getString("licenseplate"));
        vehicleDto.setMileage(rs.getInt("mileage"));
        return vehicleDto;
    }
}
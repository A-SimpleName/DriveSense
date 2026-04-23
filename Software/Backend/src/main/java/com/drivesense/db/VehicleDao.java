package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.exceptions.DatabaseException;
import com.drivesense.model.Vehicle;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Repository
public class VehicleDao {

    @Autowired
    private DbConnection dbConnection;

    public List<VehicleDto> getAllVehicles() {
        String sql =
                "SELECT v.id, v.model, p.name, v.licenseplate, v.mileage " +
                        "FROM vehicle v " +
                        "JOIN profile_vehicle pv ON v.id = pv.vehicle_id " +
                        "JOIN profile p ON pv.profile_id = p.id";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<VehicleDto> list = new ArrayList<>();

            while (rs.next()) {
                list.add(mapDto(rs));
            }

            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden der Vehicles", e);
        }
    }

    public List<VehicleDto> getAllVehiclesByAccount(int accountId) {
        String sql =
                "SELECT v.id, v.model, p.name, v.licenseplate, v.mileage " +
                        "FROM vehicle v " +
                        "JOIN profile_vehicle pv ON v.id = pv.vehicle_id " +
                        "JOIN profile p ON pv.profile_id = p.id " +
                        "WHERE p.account_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, accountId);

            ResultSet rs = ps.executeQuery();
            List<VehicleDto> list = new ArrayList<>();

            while (rs.next()) {
                list.add(mapDto(rs));
            }

            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden der Vehicles", e);
        }
    }

    public Vehicle getById(int id, int profileId) {
        String sql =
                "SELECT v.* " +
                        "FROM vehicle v " +
                        "JOIN profile_vehicle pv ON v.id = pv.vehicle_id " +
                        "WHERE v.id = ? AND pv.profile_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.setInt(2, profileId);

            ResultSet rs = ps.executeQuery();
            if (rs.next()) return map(rs);

            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Vehicles", e);
        }
    }

    public Vehicle insert(Vehicle vehicle, int profileId) {
        String sqlVehicle = "INSERT INTO vehicle (model, licenseplate, mileage) VALUES (?,?,?)";
        String sqlLink = "INSERT INTO profile_vehicle (profile_id, vehicle_id, role) VALUES (?,?,?)";

        try (Connection conn = dbConnection.getConnection()) {

            conn.setAutoCommit(false);

            // 1. Vehicle speichern
            PreparedStatement ps1 = conn.prepareStatement(sqlVehicle, Statement.RETURN_GENERATED_KEYS);
            ps1.setString(1, vehicle.getModel());
            ps1.setString(2, vehicle.getLicensePlate());
            ps1.setInt(3, vehicle.getMileage());
            ps1.executeUpdate();

            ResultSet rs = ps1.getGeneratedKeys();
            if (rs.next()) {
                int vehicleId = rs.getInt(1);
                vehicle.setId(vehicleId);

                // 2. Beziehung speichern
                PreparedStatement ps2 = conn.prepareStatement(sqlLink);
                ps2.setInt(1, profileId);
                ps2.setInt(2, vehicleId);
                ps2.setString(3, "OWNER");

                ps2.executeUpdate();
            }

            conn.commit();
            return vehicle;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim speichern des Vehicles", e);
        }
    }

    public void update(Vehicle vehicle, int profileId) {
        String sql =
                "UPDATE vehicle v " +
                        "JOIN profile_vehicle pv ON v.id = pv.vehicle_id " +
                        "SET v.model = ?, v.licenseplate = ?, v.mileage = ? " +
                        "WHERE v.id = ? AND pv.profile_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, vehicle.getModel());
            ps.setString(2, vehicle.getLicensePlate());
            ps.setInt(3, vehicle.getMileage());
            ps.setInt(4, vehicle.getId());
            ps.setInt(5, profileId);

            ps.executeUpdate();

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim aktualisieren des Vehicles", e);
        }
    }

    public void deleteById(int id, int accountId) {
        String sql =
                "DELETE v FROM vehicle v " +
                        "JOIN profile_vehicle pv ON v.id = pv.vehicle_id " +
                        "JOIN profile p ON pv.profile_id = p.id " +
                        "WHERE v.id = ? AND p.account_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.setInt(2, accountId);

            ps.executeUpdate();

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim löschen des Vehicles", e);
        }
    }

    private Vehicle map(ResultSet rs) throws SQLException {
        Vehicle v = new Vehicle();
        v.setId(rs.getInt("id"));
        v.setModel(rs.getString("model"));
        v.setLicensePlate(rs.getString("licenseplate"));
        v.setMileage(rs.getInt("mileage"));
        return v;
    }

    private VehicleDto mapDto(ResultSet rs) throws SQLException {
        VehicleDto dto = new VehicleDto();
        dto.setId(rs.getInt("id"));
        dto.setProfileName(rs.getString("name"));
        dto.setModel(rs.getString("model"));
        dto.setLicensePlate(rs.getString("licenseplate"));
        dto.setMileage(rs.getInt("mileage"));
        return dto;
    }
}
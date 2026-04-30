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
        String sql = "SELECT v.id, v.model, " +
                "GROUP_CONCAT(p.name ORDER BY FIELD(pv.role, 'OWNER', 'CO_OWNER', 'DRIVER'), p.name SEPARATOR ', ') AS profile_name, " +
                "v.licenseplate, v.mileage " +
                "FROM vehicle v " +
                "JOIN profile_vehicle pv ON pv.vehicle_id = v.id " +
                "JOIN profile p ON p.id = pv.profile_id " +
                "GROUP BY v.id, v.model, v.licenseplate, v.mileage";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            List<VehicleDto> vehicleDtos = new ArrayList<>();
            while (rs.next()) {
                vehicleDtos.add(mapDto(rs));
            }
            return vehicleDtos;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden der Vehicles", e);
        }
    }

    public List<VehicleDto> getAllVehiclesByAccount(int accountId) {
        String sql = "SELECT v.id, v.model, " +
                "GROUP_CONCAT(p.name ORDER BY FIELD(pv.role, 'OWNER', 'CO_OWNER', 'DRIVER'), p.name SEPARATOR ', ') AS profile_name, " +
                "v.licenseplate, v.mileage " +
                "FROM vehicle v " +
                "JOIN profile_vehicle pv ON pv.vehicle_id = v.id " +
                "JOIN profile p ON p.id = pv.profile_id " +
                "WHERE p.account_id = ? " +
                "GROUP BY v.id, v.model, v.licenseplate, v.mileage";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, accountId); // WICHTIG

            ResultSet rs = ps.executeQuery();
            List<VehicleDto> vehicleDtos = new ArrayList<>();

            while (rs.next()) {
                vehicleDtos.add(mapDto(rs));
            }
            return vehicleDtos;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden der Vehicles", e);
        }
    }

    public Vehicle getById(int id) {
        String sql = "SELECT v.*, (" +
                "SELECT pv.profile_id " +
                "FROM profile_vehicle pv " +
                "WHERE pv.vehicle_id = v.id " +
                "ORDER BY FIELD(pv.role, 'OWNER', 'CO_OWNER', 'DRIVER'), pv.profile_id " +
                "LIMIT 1" +
                ") AS profile_id " +
                "FROM vehicle v WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return map(rs);
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Vehicles", e);
        }
    }

    public Vehicle insert(Vehicle vehicle) {
        String vehicleSql = "INSERT INTO vehicle (model, licenseplate, mileage) VALUES (?,?,?)";
        String profileVehicleSql = "INSERT INTO profile_vehicle (profile_id, vehicle_id, role) VALUES (?,?,'OWNER')";

        try (Connection conn = dbConnection.getConnection()) {
            conn.setAutoCommit(false);

            try (PreparedStatement vehiclePs = conn.prepareStatement(vehicleSql, Statement.RETURN_GENERATED_KEYS);
                 PreparedStatement profileVehiclePs = conn.prepareStatement(profileVehicleSql)) {

                vehiclePs.setString(1, vehicle.getModel());
                vehiclePs.setString(2, vehicle.getLicensePlate());
                vehiclePs.setInt(3, vehicle.getMileage());
                vehiclePs.executeUpdate();

                try (ResultSet rs = vehiclePs.getGeneratedKeys()) {
                    if (!rs.next()) {
                        throw new SQLException("Keine Fahrzeug-ID nach dem Insert erhalten");
                    }
                    vehicle.setId(rs.getInt(1));
                }

                profileVehiclePs.setInt(1, vehicle.getProfileId());
                profileVehiclePs.setInt(2, vehicle.getId());
                profileVehiclePs.executeUpdate();

                conn.commit();
                return vehicle;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim speichern des Vehicles", e);
        }
    }

    public void update(Vehicle vehicle) {
        String sql = "UPDATE vehicle SET model = ?, licenseplate = ?, mileage = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, vehicle.getModel());
            ps.setString(2, vehicle.getLicensePlate());
            ps.setInt(3, vehicle.getMileage());
            ps.setInt(4, vehicle.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim aktualisieren des Vehicles", e);
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM vehicle WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim löschen der Vehicles", e);
        }
    }

    public boolean isAssignedToProfile(int profileId, int vehicleId) {
        String sql = "SELECT 1 FROM profile_vehicle WHERE profile_id = ? AND vehicle_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, profileId);
            ps.setInt(2, vehicleId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Prüfen der Fahrzeug-Zuordnung", e);
        }
    }

    private Vehicle map(ResultSet rs) throws SQLException {
        Vehicle v = new Vehicle();
        v.setId(rs.getInt("id"));
        v.setProfileId(rs.getInt("profile_id"));
        v.setModel(rs.getString("model"));
        v.setLicensePlate(rs.getString("licenseplate"));
        v.setMileage(rs.getInt("mileage"));
        return v;
    }

    private VehicleDto mapDto(ResultSet rs) throws SQLException {
        VehicleDto dto = new VehicleDto();
        dto.setId(rs.getInt("id"));
        dto.setProfileName(rs.getString("profile_name"));
        dto.setModel(rs.getString("model"));
        dto.setLicensePlate(rs.getString("licenseplate"));
        dto.setMileage(rs.getInt("mileage"));
        return dto;
    }
}

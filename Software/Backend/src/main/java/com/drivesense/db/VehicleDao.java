package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.exceptions.BadRequestException;
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

    public List<VehicleDto> getAllVehiclesByAccount(int accountId) {
        String sql =
                "SELECT v.id, v.model, v.licenseplate, v.mileage, " +
                        "       acc.fname AS owner_account_name, " +
                        "       p.name AS owner_profile_name, " +
                        "       pv2.role AS my_role " +
                        "FROM vehicle v " +
                        "JOIN profile_vehicle pv2 ON pv2.vehicle_id = v.id " +
                        "JOIN profile p2 ON p2.id = pv2.profile_id AND p2.account_id = ? " +
                        "JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER' " +
                        "JOIN profile p ON p.id = pv_owner.profile_id " +
                        "JOIN account acc ON acc.id = p.account_id";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, accountId);

            ResultSet rs = ps.executeQuery();
            List<VehicleDto> list = new ArrayList<>();

            while (rs.next()) {
                list.add(mapDetail(rs));
            }

            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Vehicles", e);
        }
    }

    public List<VehicleDto> getAllVehiclesByProfile(int profileId) {
        String sql =
                "SELECT v.id, v.model, v.licenseplate, v.mileage, " +
                        "       acc.fname AS owner_account_name, " +
                        "       p_owner.name AS owner_profile_name, " +
                        "       pv.role AS my_role " +
                        "FROM profile_vehicle pv " +
                        "JOIN vehicle v ON v.id = pv.vehicle_id " +
                        "JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER' " +
                        "JOIN profile p_owner ON p_owner.id = pv_owner.profile_id " +
                        "JOIN account acc ON acc.id = p_owner.account_id " +
                        "WHERE pv.profile_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, profileId);

            ResultSet rs = ps.executeQuery();
            List<VehicleDto> list = new ArrayList<>();

            while (rs.next()) {
                list.add(mapDetail(rs));
            }

            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Vehicles", e);
        }
    }

    public VehicleDto getById(int vehicleId, int accountId) {
        String sql =
                "SELECT v.id, v.model, v.licenseplate, v.mileage, " +
                        "       acc.fname AS owner_account_name, " +
                        "       p.name AS owner_profile_name, " +
                        "       pv.role AS my_role " +
                        "FROM vehicle v " +
                        "JOIN profile_vehicle pv ON pv.vehicle_id = v.id " +
                        "JOIN profile p_user ON p_user.id = pv.profile_id AND p_user.account_id = ? " +
                        "JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER' " +
                        "JOIN profile p ON p.id = pv_owner.profile_id " +
                        "JOIN account acc ON acc.id = p.account_id " +
                        "WHERE v.id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, accountId);
            ps.setInt(2, vehicleId);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return mapDetail(rs);
            }

            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden des Vehicles", e);
        }
    }

    public Vehicle insert(Vehicle vehicle, int profileId) {
        String sqlVehicle = "INSERT INTO vehicle (model, licenseplate, mileage) VALUES (?,?,?)";
        String sqlLink = "INSERT INTO profile_vehicle (profile_id, vehicle_id, role) VALUES (?,?,?)";

        try (Connection conn = dbConnection.getConnection()) {

            conn.setAutoCommit(false);

            try {
                try (PreparedStatement ps1 = conn.prepareStatement(sqlVehicle, Statement.RETURN_GENERATED_KEYS)) {
                    ps1.setString(1, vehicle.getModel());
                    ps1.setString(2, vehicle.getLicensePlate());
                    ps1.setInt(3, vehicle.getMileage());
                    ps1.executeUpdate();

                    try (ResultSet rs = ps1.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new SQLException("Keine generierte Fahrzeug-ID erhalten");
                        }

                        int vehicleId = rs.getInt(1);
                        vehicle.setId(vehicleId);

                        try (PreparedStatement ps2 = conn.prepareStatement(sqlLink)) {
                            ps2.setInt(1, profileId);
                            ps2.setInt(2, vehicleId);
                            ps2.setString(3, "OWNER");
                            ps2.executeUpdate();
                        }
                    }
                }

                conn.commit();
                return vehicle;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }

        } catch (SQLException e) {
            if ("23000".equals(e.getSQLState()) && e.getMessage() != null
                    && e.getMessage().contains("uq_vehicle_licenseplate")) {
                throw new BadRequestException("Kennzeichen ist bereits vergeben");
            }
            throw new DatabaseException("Fehler beim Speichern des Vehicles", e);
        }
    }

    public void update(Vehicle vehicle, int accountId) {
        String sql =
                "UPDATE vehicle v " +
                        "JOIN profile_vehicle pv ON pv.vehicle_id = v.id " +
                        "JOIN profile p ON p.id = pv.profile_id " +
                        "SET v.model = ?, v.licenseplate = ?, v.mileage = ? " +
                        "WHERE v.id = ? AND p.account_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, vehicle.getModel());
            ps.setString(2, vehicle.getLicensePlate());
            ps.setInt(3, vehicle.getMileage());
            ps.setInt(4, vehicle.getId());
            ps.setInt(5, accountId);

            ps.executeUpdate();

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Updaten des Vehicles", e);
        }
    }

    public void deleteById(int vehicleId, int accountId) {
        String sql =
                "DELETE v FROM vehicle v " +
                        "JOIN profile_vehicle pv ON pv.vehicle_id = v.id " +
                        "JOIN profile p ON p.id = pv.profile_id " +
                        "WHERE v.id = ? " +
                        "AND p.account_id = ? " +
                        "AND pv.role = 'OWNER'";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, vehicleId);
            ps.setInt(2, accountId);

            ps.executeUpdate();

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Löschen des Vehicles", e);
        }
    }

    public List<VehicleDto> getAllVehicles() {
        String sql =
                "SELECT v.id, v.model, v.licenseplate, v.mileage, " +
                        "       acc.fname AS owner_account_name, " +
                        "       p.name AS owner_profile_name, " +
                        "       pv_user.role AS my_role " +
                        "FROM vehicle v " +
                        "JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER' " +
                        "JOIN profile p ON p.id = pv_owner.profile_id " +
                        "JOIN account acc ON acc.id = p.account_id " +
                        "LEFT JOIN profile_vehicle pv_user ON pv_user.vehicle_id = v.id";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<VehicleDto> list = new ArrayList<>();

            while (rs.next()) {
                list.add(mapDetail(rs));
            }

            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden aller Vehicles", e);
        }
    }

    private VehicleDto mapDetail(ResultSet rs) throws SQLException {
        VehicleDto dto = new VehicleDto();

        dto.setId(rs.getInt("id"));
        dto.setModel(rs.getString("model"));
        dto.setLicensePlate(rs.getString("licenseplate"));
        dto.setMileage(rs.getInt("mileage"));

        dto.setOwnerAccountName(rs.getString("owner_account_name"));
        dto.setOwnerProfileName(rs.getString("owner_profile_name"));

        dto.setMyRole(rs.getString("my_role"));

        return dto;
    }
}

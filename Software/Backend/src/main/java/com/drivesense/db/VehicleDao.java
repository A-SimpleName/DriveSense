package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.dto.VehicleDto;
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

    public List<VehicleDto> getAllVehiclesByAccount() {
        String sql = "SELECT v.id, v.model, u.name, v.licenseplate, v.mileage " +
                "FROM vehicle v " +
                "JOIN user u ON v.user_id = u.id";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            List<VehicleDto> vehicleDtos = new ArrayList<>();
            while (rs.next()) {
                vehicleDtos.add(mapDto(rs));
            }
            return vehicleDtos;
        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return new ArrayList<>();
        }
    }

    public Vehicle getById(int id) {
        String sql = "SELECT * FROM vehicle WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return map(rs);
            return null;
        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public Vehicle insert(Vehicle vehicle) {
        String sql = "INSERT INTO vehicle (user_id, model, licenseplate, mileage) VALUES (?,?,?,?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, vehicle.getUserId());
            ps.setString(2, vehicle.getModel());
            ps.setString(3, vehicle.getLicenseplate());
            ps.setInt(4, vehicle.getMileage());
            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                vehicle.setId(rs.getInt(1));
            }
            return vehicle;
        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public void update(Vehicle vehicle) {
        String sql = "UPDATE vehicle SET model = ?, licenseplate = ?, mileage = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, vehicle.getModel());
            ps.setString(2, vehicle.getLicenseplate());
            ps.setInt(3, vehicle.getMileage());
            ps.setInt(4, vehicle.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM vehicle WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    // Mapping
    private Vehicle map(ResultSet rs) throws SQLException {
        Vehicle v = new Vehicle();
        v.setId(rs.getInt("id"));
        v.setUserId(rs.getInt("user_id"));
        v.setModel(rs.getString("model"));
        v.setLicenseplate(rs.getString("licenseplate"));
        v.setMileage(rs.getInt("mileage"));
        return v;
    }

    private VehicleDto mapDto(ResultSet rs) throws SQLException {
        VehicleDto dto = new VehicleDto();
        dto.setId(rs.getInt("id"));
        dto.setUserName(rs.getString("name"));
        dto.setModel(rs.getString("model"));
        dto.setLicencePlate(rs.getString("licenseplate"));
        dto.setMileage(rs.getInt("mileage"));
        return dto;
    }
}
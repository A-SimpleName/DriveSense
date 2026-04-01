package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.exceptions.*;
import com.drivesense.dto.response.TripSummaryDto;
import com.drivesense.model.TripSummary;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class TripDao {

    private final DbConnection dbConnection;

    @Autowired
    public TripDao(DbConnection dbConnection) {
        this.dbConnection = dbConnection;
    }

    public int insert(TripSummary tripSummary) {
        String sql = "INSERT INTO trip (profile_id, vehicle_id, protocol_id, starttime, endtime, distance, road_surface_conditions, type) VALUES (?,?,?,?,?,?,?,?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, tripSummary.getProfileId());
            ps.setInt(2, tripSummary.getVehicleId());
            ps.setInt(3, tripSummary.getProtocolId());
            ps.setObject(4, tripSummary.getStartTime());
            ps.setObject(5, tripSummary.getEndTime());
            ps.setDouble(6, tripSummary.getDistance());
            ps.setString(7, tripSummary.getRoadSurfaceConditions());
            ps.setString(8, tripSummary.getType());

            ps.executeUpdate();

            try (ResultSet generatedKeys = ps.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    return generatedKeys.getInt(1);
                } else {
                    throw new DatabaseException("Keine Trip ID zurückgegeben", new SQLException());
                }
            }
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Speichern der Fahrt", e);
        }
    }

    public TripSummary getById(int id) {
        String sql = "SELECT * FROM trip WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) return map(rs);
            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrt", e);
        }
    }

    public List<TripSummary> getByProfileId(int profileId) {
        String sql = "SELECT * FROM trip WHERE profile_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, profileId);
            ResultSet rs = ps.executeQuery();

            List<TripSummary> tripSummaries = new ArrayList<>();
            while (rs.next()) {
                tripSummaries.add(map(rs));
            }
            return tripSummaries;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrten", e);
        }
    }

    public TripSummary getByIdAndProfileId(int id, int profileId) {
        String sql = "SELECT * FROM trip WHERE id = ? AND profile_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.setInt(2, profileId);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) return map(rs);
            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrt", e);
        }
    }

    public List<TripSummaryDto> getAllByProfileAndProtocolId(int profileId, int protocolId) {
        String sql = """
        SELECT
            t.id,
            t.distance,
            t.type,
            v.model AS vehicle_model,
            a.fname,
            a.lname
        FROM trip t
        JOIN vehicle v ON t.vehicle_id = v.id
        JOIN profile p ON t.profile_id = p.id
        JOIN account a ON p.account_id = a.id
        WHERE t.profile_id = ? AND t.protocol_id = ?
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, protocolId);
            ps.setInt(2, profileId);
            ResultSet rs = ps.executeQuery();

            List<TripSummaryDto> tripSummaries = new ArrayList<>();
            while (rs.next()) {
                tripSummaries.add(mapToDto(rs));
            }
            return tripSummaries;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }
    public List<TripSummaryDto> getAllByProtocolId(int protocolId) {
        String sql = """
        SELECT
            t.id,
            t.distance,
            t.type,
            v.model AS vehicle_model,
            a.fname,
            a.lname
        FROM trip t
        JOIN vehicle v ON t.vehicle_id = v.id
        JOIN profile p ON t.profile_id = p.id
        JOIN account a ON p.account_id = a.id
        WHERE t.protocol_id = ?
    """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, protocolId);
            ResultSet rs = ps.executeQuery();

            List<TripSummaryDto> tripSummaries = new ArrayList<>();
            while (rs.next()) {
                tripSummaries.add(mapToDto(rs));
            }
            return tripSummaries;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrten", e);
        }
    }

    public List<TripSummary> getAll() {
        String sql = "SELECT * FROM trip";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<TripSummary> tripSummaries = new ArrayList<>();
            while (rs.next()) {
                tripSummaries.add(map(rs));
            }
            return tripSummaries;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden aller Fahrten", e);
        }
    }

    public void update(TripSummary tripSummary) {
        String sql = "UPDATE trip SET starttime = ?, endtime = ?, distance = ?, road_surface_conditions = ?, type = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, tripSummary.getStartTime());
            ps.setObject(2, tripSummary.getEndTime());
            ps.setDouble(3, tripSummary.getDistance());
            ps.setString(4, tripSummary.getRoadSurfaceConditions());
            ps.setString(5, tripSummary.getType());
            ps.setInt(6, tripSummary.getId());

            ps.executeUpdate();

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren der Fahrt", e);
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM trip WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.executeUpdate();

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Löschen der Fahrt", e);
        }
    }

    private TripSummary map(ResultSet rs) throws SQLException {
        TripSummary tripSummary = new TripSummary();
        tripSummary.setId(rs.getInt("id"));
        tripSummary.setProfileId(rs.getInt("profile_id"));
        tripSummary.setVehicleId(rs.getInt("vehicle_id"));
        tripSummary.setProtocolId(rs.getInt("protocol_id"));
        tripSummary.setStartTime((LocalDateTime) rs.getObject("starttime"));
        tripSummary.setEndTime((LocalDateTime) rs.getObject("endtime"));
        tripSummary.setDistance(rs.getDouble("distance"));
        tripSummary.setRoadSurfaceConditions(rs.getString("road_surface_conditions"));
        tripSummary.setType(rs.getString("type"));
        return tripSummary;
    }

    private TripSummaryDto mapToDto(ResultSet rs) throws SQLException {
        TripSummaryDto dto = new TripSummaryDto();

        dto.setId(rs.getInt("id"));
        dto.setDistance(rs.getDouble("distance"));
        dto.setType(rs.getString("type"));
        dto.setVehicleModel(rs.getString("vehicle_model"));
        dto.setAccountFname(rs.getString("fname"));
        dto.setAccountLname(rs.getString("lname"));

        return dto;
    }
}
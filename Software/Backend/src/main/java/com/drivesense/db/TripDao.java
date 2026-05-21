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
        String sql = "INSERT INTO trip (profile_id, vehicle_id, protocol_id, starttime, endtime, distance, road_surface_conditions, type, start_point, end_point, furthest_point, start_mileage, end_mileage) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)";
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
            ps.setString(9, tripSummary.getStartPoint());
            ps.setString(10, tripSummary.getEndPoint());
            ps.setString(11, tripSummary.getFurthestPoint());
            ps.setInt(12, tripSummary.getStartMileage());
            ps.setInt(13, tripSummary.getEndMileage());
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

    public List<TripSummaryDto> getAllByProfileAndProtocolId(int protocolId, int profileId) {
        String sql = """
                SELECT
                    t.id,
                    t.profile_id,
                    t.vehicle_id,
                    t.protocol_id,
                    t.starttime,
                    t.endtime,
                    t.distance,
                    t.start_mileage,
                    t.end_mileage,
                    v.licenseplate,
                    v.model AS vehicle_model,
                    t.start_point,
                    t.furthest_point,
                    t.end_point,
                    t.road_surface_conditions,
                    t.type,
                    a.fname,
                    a.lname
                FROM trip t
                JOIN protocol pr ON t.protocol_id = pr.id
                JOIN vehicle v ON t.vehicle_id = v.id
                JOIN profile prf ON t.profile_id = prf.id
                JOIN account a ON prf.account_id = a.id
                WHERE t.protocol_id = ?
                  AND (
                        (pr.usergroup_id IS NULL
                         AND pr.created_by_profile_id = ?)
                     OR
                        (pr.usergroup_id IS NOT NULL
                         AND EXISTS (
                             SELECT 1
                             FROM profile_usergroup pug
                             WHERE pug.usergroup_id = pr.usergroup_id
                               AND pug.profile_id = ?
                         ))
                      );
                """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, protocolId);
            ps.setInt(2, profileId);
            ps.setInt(3, profileId);
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

    /***
     * Für Admin Zwecke, keine Zugriffsrechtprüfung vorhanden!
     ***/
    public List<TripSummaryDto> getAllByProtocolId(int protocolId) {
        String sql = """
                    SELECT
                                t.id,
                                t.profile_id,
                                t.vehicle_id,
                                t.protocol_id,
                                t.starttime,
                                t.endtime,
                                t.distance,
                                t.start_mileage,
                                t.end_mileage,
                                v.licenseplate,
                                v.model AS vehicle_model,
                                t.start_point,
                                t.furthest_point,
                                t.end_point,
                                t.road_surface_conditions,
                                t.type,
                                a.fname,
                                a.lname
                            FROM trip t
                            JOIN protocol pr ON t.protocol_id = pr.id
                            JOIN vehicle v ON t.vehicle_id = v.id
                            JOIN profile prf ON t.profile_id = prf.id
                            JOIN account a ON prf.account_id = a.id
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

    public List<TripSummaryDto> getAllByProfileId(int profileId) {
        String sql = """
                SELECT
                    t.id,
                    t.profile_id,
                    t.vehicle_id,
                    t.protocol_id,
                    t.starttime,
                    t.endtime,
                    t.distance,
                    t.start_mileage,
                    t.end_mileage,
                    v.licenseplate,
                    v.model AS vehicle_model,
                    t.start_point,
                    t.furthest_point,
                    t.end_point,
                    t.road_surface_conditions,
                    t.type,
                    a.fname,
                    a.lname
                FROM trip t
                JOIN protocol pr ON t.protocol_id = pr.id
                JOIN vehicle v ON t.vehicle_id = v.id
                JOIN profile prf ON t.profile_id = prf.id
                JOIN account a ON prf.account_id = a.id
                WHERE t.profile_id = ?
                """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, profileId);
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

    public TripSummaryDto getLatestTrackedByProfileId(int profileId) {
        String sql = """
                SELECT
                    t.id,
                    t.profile_id,
                    t.vehicle_id,
                    t.protocol_id,
                    t.starttime,
                    t.endtime,
                    t.distance,
                    t.start_mileage,
                    t.end_mileage,
                    v.licenseplate,
                    v.model AS vehicle_model,
                    t.start_point,
                    t.furthest_point,
                    t.end_point,
                    t.road_surface_conditions,
                    t.type,
                    a.fname,
                    a.lname
                FROM trip t
                JOIN vehicle v ON t.vehicle_id = v.id
                JOIN profile prf ON t.profile_id = prf.id
                JOIN account a ON prf.account_id = a.id
                WHERE t.profile_id = ?
                  AND t.endtime IS NOT NULL
                  AND EXISTS (
                      SELECT 1
                      FROM trackingpoint tp
                      WHERE tp.trip_id = t.id
                  )
                ORDER BY t.endtime DESC, t.starttime DESC, t.id DESC
                LIMIT 1
                """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, profileId);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) return mapToDto(rs);
            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der letzten Fahrt", e);
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
        String sql = "UPDATE trip SET starttime = ?, endtime = ?, distance = ?, road_surface_conditions = ?, type = ?, start_point = ?, end_point = ?, furthest_point = ?, start_mileage = ?, end_mileage = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, tripSummary.getStartTime());
            ps.setObject(2, tripSummary.getEndTime());
            ps.setDouble(3, tripSummary.getDistance());
            ps.setString(4, tripSummary.getRoadSurfaceConditions());
            ps.setString(5, tripSummary.getType());
            ps.setString(6, tripSummary.getStartPoint());
            ps.setString(7, tripSummary.getEndPoint());
            ps.setString(8, tripSummary.getFurthestPoint());
            ps.setInt(9, tripSummary.getStartMileage());
            ps.setInt(10, tripSummary.getEndMileage());
            ps.setInt(11, tripSummary.getId());
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
        tripSummary.setStartPoint(rs.getString("start_point"));
        tripSummary.setEndPoint(rs.getString("end_point"));
        tripSummary.setFurthestPoint(rs.getString("furthest_point"));
        tripSummary.setStartMileage(rs.getInt("start_mileage"));
        tripSummary.setEndMileage(rs.getInt("end_mileage"));
        return tripSummary;
    }

    private TripSummaryDto mapToDto(ResultSet rs) throws SQLException {
        TripSummaryDto dto = new TripSummaryDto();

        dto.setId(rs.getInt("id"));
        dto.setProfileId(rs.getInt("profile_id"));
        dto.setVehicleId(rs.getInt("vehicle_id"));
        dto.setProtocolId(rs.getInt("protocol_id"));
        dto.setStartTime(rs.getTimestamp("starttime").toLocalDateTime());
        Timestamp endTimeTimestamp = rs.getTimestamp("endtime");
        if (endTimeTimestamp != null) {
            dto.setEndTime(endTimeTimestamp.toLocalDateTime());
        }
        dto.setStartMileage(rs.getInt("start_mileage"));
        dto.setEndMileage(rs.getInt("end_mileage"));
        dto.setDistance(rs.getDouble("distance"));
        dto.setType(rs.getString("type"));
        dto.setLicensePlate(rs.getString("licenseplate"));
        dto.setVehicleModel(rs.getString("vehicle_model"));
        dto.setStartPoint(rs.getString("start_point"));
        dto.setFurthestPoint(rs.getString("furthest_point"));
        dto.setEndPoint(rs.getString("end_point"));
        dto.setAccountFname(rs.getString("fname"));
        dto.setAccountLname(rs.getString("lname"));
        dto.setRoadSurfaceConditions(rs.getString("road_surface_conditions"));

        return dto;
    }
}

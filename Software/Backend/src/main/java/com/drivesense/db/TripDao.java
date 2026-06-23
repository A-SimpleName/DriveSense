package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.dto.response.TripSummaryDto;
import com.drivesense.exceptions.BadRequestException;
import com.drivesense.exceptions.DatabaseException;
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

    // ─────────────────────────────────────────────
    // INSERT
    // ─────────────────────────────────────────────
    public int insert(TripSummary tripSummary) {
        String sql = """
            INSERT INTO trip (
                profile_id,
                vehicle_id,
                protocol_id,
                start_time,
                end_time,
                distance,
                duration_seconds,
                road_surface_conditions,
                type,
                start_point,
                end_point,
                furthest_point,
                start_mileage,
                end_mileage,
                vehicle_model_snapshot,
                licenseplate_snapshot,
                profile_name_snapshot
            )
            SELECT
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                v.model,
                v.license_plate,
                p.name
            FROM vehicle v
            JOIN profile_vehicle pv ON pv.vehicle_id = v.id
            JOIN profile p ON p.id = pv.profile_id
            WHERE v.id = ?
              AND pv.profile_id = ?
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, tripSummary.getProfileId());
            ps.setInt(2, tripSummary.getVehicleId());
            ps.setInt(3, tripSummary.getProtocolId());
            ps.setObject(4, tripSummary.getStartTime());
            ps.setObject(5, tripSummary.getEndTime());
            ps.setDouble(6, tripSummary.getDistance());
            ps.setLong(7, tripSummary.getDurationSeconds());
            ps.setString(8, tripSummary.getRoadSurfaceConditions());
            ps.setString(9, tripSummary.getType());
            ps.setString(10, tripSummary.getStartPoint());
            ps.setString(11, tripSummary.getEndPoint());
            ps.setString(12, tripSummary.getFurthestPoint());
            ps.setInt(13, tripSummary.getStartMileage());
            ps.setInt(14, tripSummary.getEndMileage());
            ps.setInt(15, tripSummary.getVehicleId());
            ps.setInt(16, tripSummary.getProfileId());

            int insertedRows = ps.executeUpdate();
            if (insertedRows == 0) {
                throw new BadRequestException("Fahrzeug ist fuer dieses Profil nicht verfuegbar");
            }

            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
                throw new DatabaseException("Keine Trip ID zurueckgegeben", new SQLException());
            }

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Speichern der Fahrt", e);
        }
    }

    // ─────────────────────────────────────────────
    // READ SINGLE
    // ─────────────────────────────────────────────
    public TripSummary getById(int id) {
        String sql = "SELECT * FROM trip WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();

            return rs.next() ? map(rs) : null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrt", e);
        }
    }

    public TripSummary getByIdAndProfileId(int id, int profileId) {
        String sql = "SELECT * FROM trip WHERE id = ? AND profile_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.setInt(2, profileId);

            ResultSet rs = ps.executeQuery();
            return rs.next() ? map(rs) : null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrt", e);
        }
    }

    public TripSummaryDto getLatestTrackedByProfileId(int profileId) {
        String sql = """
            SELECT
                t.id,
                t.profile_id,
                t.vehicle_id,
                t.protocol_id,
                pr.name AS protocol_name,
                t.start_time,
                t.end_time,
                t.distance,
                t.duration_seconds,
                t.start_mileage,
                t.end_mileage,
                t.licenseplate_snapshot AS license_plate,
                t.vehicle_model_snapshot AS vehicle_model,
                t.start_point,
                t.furthest_point,
                t.end_point,
                t.road_surface_conditions,
                t.type,
                a.first_name,
                a.last_name
            FROM trip t
            JOIN protocol pr ON t.protocol_id = pr.id
            JOIN profile prf ON t.profile_id = prf.id
            JOIN account a ON prf.account_id = a.id
            WHERE t.profile_id = ?
              AND t.end_time IS NOT NULL
              AND EXISTS (
                  SELECT 1
                  FROM trackingpoint tp
                  WHERE tp.trip_id = t.id
              )
            ORDER BY t.end_time DESC, t.start_time DESC, t.id DESC
            LIMIT 1
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, profileId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapToDto(rs) : null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der letzten Fahrt", e);
        }
    }

    public List<TripSummaryDto> getAllByProtocolId(int protocolId) {
        String sql = """
            SELECT
                t.id,
                t.profile_id,
                t.vehicle_id,
                t.protocol_id,
                pr.name AS protocol_name,
                t.start_time,
                t.end_time,
                t.distance,
                t.duration_seconds,
                t.start_mileage,
                t.end_mileage,
                t.licenseplate_snapshot AS license_plate,
                t.vehicle_model_snapshot AS vehicle_model,
                t.start_point,
                t.furthest_point,
                t.end_point,
                t.road_surface_conditions,
                t.type,
                a.first_name,
                a.last_name
            FROM trip t
            JOIN protocol pr ON t.protocol_id = pr.id
            JOIN profile prf ON t.profile_id = prf.id
            JOIN account a ON prf.account_id = a.id
            WHERE t.protocol_id = ?
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, protocolId);
            ResultSet rs = ps.executeQuery();

            List<TripSummaryDto> list = new ArrayList<>();
            while (rs.next()) list.add(mapToDto(rs));
            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrten", e);
        }
    }

    public List<TripSummary> getByProfileId(int profileId) {
        String sql = "SELECT * FROM trip WHERE profile_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, profileId);
            ResultSet rs = ps.executeQuery();

            List<TripSummary> list = new ArrayList<>();
            while (rs.next()) list.add(map(rs));
            return list;

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
                pr.name AS protocol_name,
                t.start_time,
                t.end_time,
                t.distance,
                t.duration_seconds,
                t.start_mileage,
                t.end_mileage,
                t.licenseplate_snapshot AS license_plate,
                t.vehicle_model_snapshot AS vehicle_model,
                t.start_point,
                t.furthest_point,
                t.end_point,
                t.road_surface_conditions,
                t.type,
                a.first_name,
                a.last_name
            FROM trip t
            JOIN protocol pr ON t.protocol_id = pr.id
            JOIN profile prf ON t.profile_id = prf.id
            JOIN account a ON prf.account_id = a.id
            WHERE t.profile_id = ?
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, profileId);
            ResultSet rs = ps.executeQuery();

            List<TripSummaryDto> list = new ArrayList<>();
            while (rs.next()) list.add(mapToDto(rs));
            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrten", e);
        }
    }

    public List<TripSummary> getAll() {
        String sql = "SELECT * FROM trip";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();

            List<TripSummary> list = new ArrayList<>();
            while (rs.next()) list.add(map(rs));
            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden aller Fahrten", e);
        }
    }

    // ─────────────────────────────────────────────
    // DTO QUERIES (ACCESS CONTROL)
    // ─────────────────────────────────────────────
    public TripSummaryDto getDtoByIdAccessibleByProfile(int id, int profileId) {
        String sql = """
            SELECT
                t.id,
                t.profile_id,
                t.vehicle_id,
                t.protocol_id,
                pr.name AS protocol_name,
                t.start_time,
                t.end_time,
                t.distance,
                t.duration_seconds,
                t.start_mileage,
                t.end_mileage,
                t.licenseplate_snapshot AS license_plate,
                t.vehicle_model_snapshot AS vehicle_model,
                t.start_point,
                t.furthest_point,
                t.end_point,
                t.road_surface_conditions,
                t.type,
                a.first_name,
                a.last_name
            FROM trip t
            JOIN protocol pr ON t.protocol_id = pr.id
            JOIN profile prf ON t.profile_id = prf.id
            JOIN account a ON prf.account_id = a.id
            WHERE t.id = ?
              AND (
                    (pr.usergroup_id IS NULL AND pr.created_by_profile_id = ?)
                 OR (pr.usergroup_id IS NOT NULL AND EXISTS (
                        SELECT 1
                        FROM profile_usergroup pug
                        WHERE pug.usergroup_id = pr.usergroup_id
                          AND pug.profile_id = ?
                 ))
              )
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.setInt(2, profileId);
            ps.setInt(3, profileId);

            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapToDto(rs) : null;

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
                pr.name AS protocol_name,
                t.start_time,
                t.end_time,
                t.distance,
                t.duration_seconds,
                t.start_mileage,
                t.end_mileage,
                t.licenseplate_snapshot AS license_plate,
                t.vehicle_model_snapshot AS vehicle_model,
                t.start_point,
                t.furthest_point,
                t.end_point,
                t.road_surface_conditions,
                t.type,
                a.first_name,
                a.last_name
            FROM trip t
            JOIN protocol pr ON t.protocol_id = pr.id
            JOIN profile prf ON t.profile_id = prf.id
            JOIN account a ON prf.account_id = a.id
            WHERE t.protocol_id = ?
              AND (
                    (pr.usergroup_id IS NULL AND pr.created_by_profile_id = ?)
                 OR (pr.usergroup_id IS NOT NULL AND EXISTS (
                        SELECT 1
                        FROM profile_usergroup pug
                        WHERE pug.usergroup_id = pr.usergroup_id
                          AND pug.profile_id = ?
                 ))
              )
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, protocolId);
            ps.setInt(2, profileId);
            ps.setInt(3, profileId);

            ResultSet rs = ps.executeQuery();

            List<TripSummaryDto> list = new ArrayList<>();
            while (rs.next()) list.add(mapToDto(rs));
            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrten", e);
        }
    }

    public void update(TripSummary tripSummary) {
        String sql = """
            UPDATE trip SET
                start_time = ?,
                end_time = ?,
                distance = ?,
                duration_seconds = ?,
                road_surface_conditions = ?,
                type = ?,
                start_point = ?,
                end_point = ?,
                furthest_point = ?,
                start_mileage = ?,
                end_mileage = ?,
                vehicle_id = ?,
                protocol_id = ?
            WHERE id = ?
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, tripSummary.getStartTime());
            ps.setObject(2, tripSummary.getEndTime());
            ps.setDouble(3, tripSummary.getDistance());
            ps.setLong(4, tripSummary.getDurationSeconds());
            ps.setString(5, tripSummary.getRoadSurfaceConditions());
            ps.setString(6, tripSummary.getType());
            ps.setString(7, tripSummary.getStartPoint());
            ps.setString(8, tripSummary.getEndPoint());
            ps.setString(9, tripSummary.getFurthestPoint());
            ps.setInt(10, tripSummary.getStartMileage());
            ps.setInt(11, tripSummary.getEndMileage());
            ps.setInt(12, tripSummary.getVehicleId());
            ps.setInt(13, tripSummary.getProtocolId());
            ps.setInt(14, tripSummary.getId());

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
            throw new DatabaseException("Fehler beim Loeschen der Fahrt", e);
        }
    }

    // ─────────────────────────────────────────────
    // MAPPERS
    // ─────────────────────────────────────────────
    private TripSummary map(ResultSet rs) throws SQLException {
        TripSummary t = new TripSummary();
        t.setId(rs.getInt("id"));
        t.setProfileId(rs.getInt("profile_id"));
        t.setVehicleId(rs.getInt("vehicle_id"));
        t.setProtocolId(rs.getInt("protocol_id"));
        t.setStartTime(rs.getObject("start_time", LocalDateTime.class));
        t.setEndTime(rs.getObject("end_time", LocalDateTime.class));
        t.setDistance(rs.getDouble("distance"));
        t.setDurationSeconds(rs.getLong("duration_seconds"));
        t.setRoadSurfaceConditions(rs.getString("road_surface_conditions"));
        t.setType(rs.getString("type"));
        t.setStartPoint(rs.getString("start_point"));
        t.setEndPoint(rs.getString("end_point"));
        t.setFurthestPoint(rs.getString("furthest_point"));
        t.setStartMileage(rs.getInt("start_mileage"));
        t.setEndMileage(rs.getInt("end_mileage"));
        return t;
    }

    private TripSummaryDto mapToDto(ResultSet rs) throws SQLException {
        TripSummaryDto dto = new TripSummaryDto();

        dto.setId(rs.getInt("id"));
        dto.setProfileId(rs.getInt("profile_id"));
        dto.setVehicleId(rs.getInt("vehicle_id"));
        dto.setProtocolId(rs.getInt("protocol_id"));
        dto.setProtocolName(rs.getString("protocol_name"));

        Timestamp start = rs.getTimestamp("start_time");
        if (start != null) dto.setStartTime(start.toLocalDateTime());

        Timestamp end = rs.getTimestamp("end_time");
        if (end != null) dto.setEndTime(end.toLocalDateTime());

        dto.setDistance(rs.getDouble("distance"));
        dto.setDurationSeconds(rs.getLong("duration_seconds"));
        dto.setStartMileage(rs.getInt("start_mileage"));
        dto.setEndMileage(rs.getInt("end_mileage"));
        dto.setType(rs.getString("type"));
        dto.setLicensePlate(rs.getString("license_plate"));
        dto.setVehicleModel(rs.getString("vehicle_model"));
        dto.setStartPoint(rs.getString("start_point"));
        dto.setFurthestPoint(rs.getString("furthest_point"));
        dto.setEndPoint(rs.getString("end_point"));
        dto.setAccountFirstName(rs.getString("first_name"));
        dto.setAccountLastName(rs.getString("last_name"));
        dto.setRoadSurfaceConditions(rs.getString("road_surface_conditions"));

        return dto;
    }
}

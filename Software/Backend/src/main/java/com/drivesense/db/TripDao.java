package com.drivesense.db;

import com.drivesense.DbConnection;
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
                    throw new SQLException("No trip ID returned.");
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public TripSummary getById(int id) {
        String sql = "SELECT * FROM trip WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
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

    public TripSummary getByProfileId(int profileId) {
        String sql = "SELECT * FROM trip WHERE profile_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, profileId);
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

    public TripSummary getByIdAndProfileId(int id, int profileId) {
        String sql = "SELECT * FROM trip WHERE id = ? AND profile_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.setInt(2, profileId);
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

    public List<TripSummary> getAllByProfileAndProtocolId(int protocolId, int profileId) {
        String sql = """
                SELECT t.*
                     FROM trip t
                     JOIN protocol pr ON t.protocol_id = pr.id
                     WHERE pr.id = ?
                       AND (
                           (pr.usergroup_id IS NULL AND pr.created_by_profile_id = ?)
                           OR
                           (pr.usergroup_id IS NOT NULL AND EXISTS (
                               SELECT 1
                               FROM profile_usergroup pug
                               WHERE pug.usergroup_id = pr.usergroup_id
                                 AND pug.profile_id = ?
                           ))
                       )
                  """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, profileId);
            ps.setInt(2, protocolId);
            ps.setInt(3, profileId);
            ResultSet rs = ps.executeQuery();

            List<TripSummary> tripSummaries = new ArrayList<>();
            while (rs.next()) {
                tripSummaries.add(map(rs));
            }
            return tripSummaries;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public List<TripSummary> getAll () {
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
            System.err.println(e.getMessage());
            return null;
        }
    }

    public void update(TripSummary tripSummary) {
        String sql = "UPDATE trip SET  starttime = ?, endtime = ? , distance = ?, road_surface_conditions = ?, type = ? WHERE id = ?";
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
            System.err.println(e.getMessage());
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM trip WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
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

}
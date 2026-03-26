package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.exceptions.DatabaseException;
import com.drivesense.model.Trackingpoint;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class TrackingpointDao {

    private final DbConnection dbConnection;

    @Autowired
    public TrackingpointDao(DbConnection dbConnection) {
        this.dbConnection = dbConnection;
    }

    public Trackingpoint insert(Trackingpoint trackingpoint) {
        String sql = "INSERT INTO trackingpoint (trip_id, lat, lng, accuracy, speed, bearing, timestamp) VALUES (?,?,?,?,?,?,?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,trackingpoint.getTripId());
            ps.setDouble(2,trackingpoint.getLat());
            ps.setDouble(3,trackingpoint.getLng());
            ps.setDouble(4,trackingpoint.getAccuracy());
            ps.setDouble(5,trackingpoint.getSpeed());
            ps.setDouble(6,trackingpoint.getBearing());
            ps.setObject(7,trackingpoint.getTimestamp());

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                trackingpoint.setId(rs.getInt(1));
            }
            return trackingpoint;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim speichern des Trackingpoints", e);
        }
    }

    public Trackingpoint getById(int id) {
        String sql = "SELECT * FROM trackingpoint WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return map(rs);
            }

            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Trackingpoints", e);
        }
    }

    public List<Trackingpoint> getByTripId(int tripId) {
        String sql = "SELECT * FROM trackingpoint WHERE trip_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, tripId);
            ResultSet rs = ps.executeQuery();

            List<Trackingpoint> trackingpoints = new ArrayList<>();
            while (rs.next()) {
                trackingpoints.add(map(rs));
            }
            return trackingpoints;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden der Trackingpoints", e);
        }
    }

    public List<Trackingpoint> getAll () {
        String sql = "SELECT * FROM trackingpoint";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<Trackingpoint> trackingpoints = new ArrayList<>();
            while (rs.next()) {
                trackingpoints.add(map(rs));
            }
            return trackingpoints;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden der Trackingpoints", e);
        }
    }

    public void update(Trackingpoint trackingpoint) {
        String sql = "UPDATE trackingpoint SET lat = ?, lng = ?, accuracy = ?, speed = ?, bearing = ?, timestamp = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setDouble(1,trackingpoint.getLat());
            ps.setDouble(2,trackingpoint.getLng());
            ps.setDouble(3,trackingpoint.getAccuracy());
            ps.setDouble(4,trackingpoint.getSpeed());
            ps.setDouble(5,trackingpoint.getBearing());
            ps.setObject(6,trackingpoint.getTimestamp());
            ps.setInt(7,trackingpoint.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim aktualisieren des Trackingpoints", e);
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM trackingpoint WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim löschen des Trackingpoints", e);
        }
    }

    private Trackingpoint map(ResultSet rs) throws SQLException {
        Trackingpoint trackingpoint = new Trackingpoint();
        trackingpoint.setId(rs.getInt("id"));
        trackingpoint.setTripId(rs.getInt("trip_id"));
        trackingpoint.setLat(rs.getDouble("lat"));
        trackingpoint.setLng(rs.getDouble("lng"));
        trackingpoint.setAccuracy(rs.getDouble("accuracy"));
        trackingpoint.setSpeed(rs.getDouble("speed"));
        trackingpoint.setBearing(rs.getDouble("bearing"));
        trackingpoint.setTimestamp((LocalDateTime) rs.getObject("timestamp"));
        return trackingpoint;
    }
}

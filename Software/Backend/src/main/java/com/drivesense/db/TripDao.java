package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.model.Trip;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class TripDao {

    @Autowired
    private DbConnection dbConnection;

    public Trip insert(Trip trip) {
        String sql = "INSERT INTO trip (user_id, car_id, starttime, endtime, distance, weather_main, type) VALUES (?,?,?,?,?,?,?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, trip.getUser_id());
            ps.setInt(2, trip.getCar_id());
            ps.setObject(3, trip.getStarttime());
            ps.setObject(4, trip.getEndtime());
            ps.setDouble(5, trip.getDistance());
            ps.setString(6, trip.getWeather_main());
            ps.setString(7, trip.getType());

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                trip.setId(rs.getInt(1));
            }
            return trip;
        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public Trip getById(int id) {
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

    public List<Trip> getByUserId(int userId) {
        String sql = "SELECT * FROM trip WHERE user_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();

            List<Trip> trips = new ArrayList<>();
            while (rs.next()) {
                trips.add(map(rs));
            }
            return trips;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public List<Trip> getAll () {
        String sql = "SELECT * FROM trip";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<Trip> trips = new ArrayList<>();
            while (rs.next()) {
                trips.add(map(rs));
            }
            return trips;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public void update(Trip trip) {
        String sql = "UPDATE trip SET  starttime = ?, endtime = ? , distance = ?, weather_main = ?, type = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, trip.getStarttime());
            ps.setObject(2, trip.getEndtime());
            ps.setDouble(3, trip.getDistance());
            ps.setString(4, trip.getWeather_main());
            ps.setString(5, trip.getType());
            ps.setInt(6, trip.getId());

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

    private Trip map(ResultSet rs) throws SQLException {
        Trip trip = new Trip();
        trip.setId(rs.getInt("id"));
        trip.setUser_id(rs.getInt("user_id"));
        trip.setCar_id(rs.getInt("car_id"));
        trip.setStarttime((LocalDateTime) rs.getObject("starttime"));
        trip.setEndtime((LocalDateTime) rs.getObject("endtime"));
        trip.setDistance(rs.getDouble("distance"));
        trip.setWeather_main(rs.getString("weather_main"));
        trip.setType(rs.getString("type"));
        return trip;
    }

}
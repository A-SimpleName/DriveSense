package db;

import app.App;
import model.Tracking;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class TrackingDao {
    public static void insertTracking(Tracking tracking) {
        String sql = "INSERT INTO tracking (user_id, car_id, starttime, endtime, distance, weather_main, type) VALUES (?,?,?,?,?,?,?)";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,tracking.getUser_id());
            ps.setInt(2,tracking.getCar_id());
            ps.setObject(3,tracking.getStarttime());
            ps.setObject(4,tracking.getEndtime());
            ps.setDouble(5,tracking.getDistance());
            ps.setString(6,tracking.getWeather_main());
            ps.setString(7,tracking.getType());

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                tracking.setId(rs.getInt(1));
            }
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static Tracking findById(int id) {
        String sql = "SELECT * FROM tracking WHERE id = ?";

        try (Connection conn = App.getConnection();
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

    public static List<Tracking> findAll () {
        String sql = "SELECT * FROM tracking";

        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<Tracking> trackings = new ArrayList<>();
            while (rs.next()) {
                trackings.add(map(rs));
            }
            return trackings;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public static void update(Tracking tracking) {
        String sql = "UPDATE tracking SET  starttime = ?, endtime = ? , distance = ?, weather_main = ?, type = ? WHERE id = ?";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1,tracking.getStarttime());
            ps.setObject(2,tracking.getEndtime());
            ps.setDouble(3,tracking.getDistance());
            ps.setString(4,tracking.getWeather_main());
            ps.setString(5,tracking.getType());
            ps.setInt(6,tracking.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static void deleteById(int id) {
        String sql = "DELETE FROM tracking WHERE id = ?";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static Tracking map(ResultSet rs) throws SQLException {
        Tracking tracking = new Tracking();
        tracking.setId(rs.getInt("id"));
        tracking.setUser_id(rs.getInt("user_id"));
        tracking.setCar_id(rs.getInt("car_id"));
        tracking.setStarttime((LocalDateTime) rs.getObject("starttime"));
        tracking.setEndtime((LocalDateTime) rs.getObject("endtime"));
        tracking.setDistance(rs.getDouble("distance"));
        tracking.setWeather_main(rs.getString("weather_main"));
        tracking.setType(rs.getString("type"));
        return tracking;
    }

}

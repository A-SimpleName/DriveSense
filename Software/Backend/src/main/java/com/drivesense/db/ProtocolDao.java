package com.drivesense.db;

import com.drivesense.app.App;
import com.drivesense.model.Protocol;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;


public class ProtocolDao {

    public static void insertProtocol(Protocol protocol) {
        String sql = "INSERT INTO protocol (tracking_id, road_surface_conditions) VALUES (?,?)";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,protocol.getTracking_id());
            ps.setString(2,protocol.getRoad_surface_conditions());


            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                protocol.setId(rs.getInt(1));
            }
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static Protocol findById(int id) {
        String sql = "SELECT * FROM protocol WHERE id = ?";

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

    public static List<Protocol> findAll () {
        String sql = "SELECT * FROM protocol";

        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<Protocol> protocols = new ArrayList<>();
            while (rs.next()) {
                protocols.add(map(rs));
            }
            return protocols;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public static void update(Protocol protocol) {
        String sql = "UPDATE protocol SET road_surface_conditions = ? WHERE id = ?";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, protocol.getRoad_surface_conditions());
            ps.setInt(2,protocol.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static void deleteById(int id) {
        String sql = "DELETE FROM protocol WHERE id = ?";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static Protocol map(ResultSet rs) throws SQLException {
        Protocol protocol = new Protocol();
        protocol.setId(rs.getInt("id"));
        protocol.setTracking_id(rs.getInt("tracking_id"));
        protocol.setRoad_surface_conditions(rs.getString("road_surface_conditions"));
        return protocol;
    }
}

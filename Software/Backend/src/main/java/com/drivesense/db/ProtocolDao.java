package com.drivesense.db;

import com.drivesense.App;
import com.drivesense.DbConnection;
import com.drivesense.model.Protocol;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ProtocolDao {

    @Autowired
    private DbConnection dbConnection;

    public void insert(Protocol protocol) {
        String sql = "INSERT INTO protocol (tracking_id, road_surface_conditions) VALUES (?,?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,protocol.getTrip_id());
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

    public Protocol getById(int id) {
        String sql = "SELECT * FROM protocol WHERE id = ?";

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

    public List<Protocol> getAll () {
        String sql = "SELECT * FROM protocol";

        try (Connection conn = dbConnection.getConnection();
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

    public void update(Protocol protocol) {
        String sql = "UPDATE protocol SET road_surface_conditions = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, protocol.getRoad_surface_conditions());
            ps.setInt(2,protocol.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM protocol WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    private Protocol map(ResultSet rs) throws SQLException {
        Protocol protocol = new Protocol();
        protocol.setId(rs.getInt("id"));
        protocol.setTrip_id(rs.getInt("tracking_id"));
        protocol.setRoad_surface_conditions(rs.getString("road_surface_conditions"));
        return protocol;
    }
}

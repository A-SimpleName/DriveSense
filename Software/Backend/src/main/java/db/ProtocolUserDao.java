package db;

import app.App;
import model.ProtocolUser;

import java.sql.*;

public class ProtocolUserDao {
    public static void insert(ProtocolUser pu) {
        String sql = "INSERT INTO protocol_user (protocol_id, user_id, user_role) VALUES (?,?,?)";

        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, pu.getProtocolId());
            ps.setInt(2, pu.getUserId());
            ps.setString(3, pu.getUserRole());

            ps.executeUpdate();

        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static void updateRole(int protocolId, int userId, String role) {
        String sql = """
        UPDATE protocol_user 
        SET user_role = ? 
        WHERE protocol_id = ? AND user_id = ?
    """;

        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, role);
            ps.setInt(2, protocolId);
            ps.setInt(3, userId);

            ps.executeUpdate();

        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static void delete(int protocolId, int userId) {
        String sql = "DELETE FROM protocol_user WHERE protocol_id = ? AND user_id = ?";

        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, protocolId);
            ps.setInt(2, userId);

            ps.executeUpdate();

        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }
}

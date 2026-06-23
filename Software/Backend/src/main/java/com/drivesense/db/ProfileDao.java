package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.exceptions.DatabaseException;
import com.drivesense.model.Profile;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ProfileDao {

    @Autowired
    private DbConnection dbConnection;

    public Profile insert(Profile profile) {
        String sql = "INSERT INTO profile (name, role, account_id) VALUES (?,?,?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, profile.getName());
            ps.setString(2, profile.getRole());
            ps.setInt(3, profile.getAccount_id());

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                profile.setId(rs.getInt(1));
            }
            return profile;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim speichern des Profils", e);
        }
    }

    public Profile getById(int id) {
        String sql = "SELECT * FROM profile WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return map(rs);
            }

            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Profils", e);
        }
    }
    /*
    public List<Profile> getByGroup_id(int group_id) {
        String sql = "SELECT * FROM profile WHERE group_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, group_id);
            ResultSet rs = ps.executeQuery();
            List<Profile> profiles = new ArrayList<>();

            while (rs.next()) {
                profiles.add(map(rs));
            }
            return profiles;

        } catch (SQLException e) {
            throw new RuntimeException(e.getMessage());
        }
    }
    */

    public List<Profile> getAll () {
        String sql = "SELECT * FROM profile";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<Profile> profiles = new ArrayList<>();
            while (rs.next()) {
                profiles.add(map(rs));
            }
            return profiles;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden der Profile", e);
        }
    }

    public void update(Profile profile) {
        String sql = "UPDATE profile SET name = ?, role = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, profile.getName());
            ps.setString(2, profile.getRole());
            ps.setInt(3, profile.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Profils", e);
        }
    }

    public void deleteById(int id) {
        String deleteVehicles = "DELETE FROM profile_vehicle WHERE profile_id = ?";
        String deleteGroups = "DELETE FROM profile_usergroup WHERE profile_id = ?";
        String anonymizeProfile = "UPDATE profile SET name = ? WHERE id = ?";

        try (Connection conn = dbConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                try (PreparedStatement ps = conn.prepareStatement(deleteVehicles)) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(deleteGroups)) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(anonymizeProfile)) {
                    ps.setString(1, "__deleted_profile_" + id + "_" + System.currentTimeMillis());
                    ps.setInt(2, id);
                    ps.executeUpdate();
                }

                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Loeschen des Profils", e);
        }
    }

    public List<Profile> getAllProfilesByAccountId(int id) {
        String sql = "SELECT * FROM profile WHERE account_id = ? AND name NOT LIKE '__deleted_profile_%'";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1,id);
            ResultSet rs = ps.executeQuery();
            List<Profile> profiles = new ArrayList<>();
            while (rs.next()) {
                profiles.add(map(rs));
            }
            return profiles;
        } catch(SQLException e) {
            throw new DatabaseException("Fehler beim laden der Profile", e);
        }
    }

    private Profile map(ResultSet rs) throws SQLException {
        Profile profile = new Profile();
        profile.setId(rs.getInt("id"));
        profile.setName(rs.getString("name"));
        profile.setRole(rs.getString("role"));
        profile.setAccount_id(rs.getInt("account_id"));
        return profile;
    }

}

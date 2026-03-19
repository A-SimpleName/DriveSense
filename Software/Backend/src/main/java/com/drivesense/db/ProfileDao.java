package com.drivesense.db;

import com.drivesense.DbConnection;
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
            System.err.println(e.getMessage());
            return null;
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
            System.err.println(e.getMessage());
            return null;
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
            System.err.println(e.getMessage());
            return null;
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
            System.err.println(e.getMessage());
            return null;
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
            System.err.println(e.getMessage());
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM profile WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public List<Profile> getAllProfilesByAccountId(int id) {
        String sql = "SELECT * FROM profile WHERE account_id = ?";
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
            System.err.println(e.getMessage());
            return new ArrayList<>();
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

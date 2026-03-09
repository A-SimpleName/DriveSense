package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.model.ProfileUsergroup;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;

@Repository
public class ProfileUsergroupDao {

    @Autowired
    private DbConnection dbConnection;

    public void insert(ProfileUsergroup pu) {
        String sql = "INSERT INTO profile_usergroup (profile_id, usergroup_id, group_role) VALUES (?,?,?)";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, pu.getProfileId());
            ps.setInt(2, pu.getUsergroupId());
            ps.setString(3, pu.getGroupRole());

            ps.executeUpdate();

        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public void updateRole(int profileId, int usergroupId, String groupRole) {
        String sql = """
        UPDATE profile_usergroup
        SET groupRole = ? 
        WHERE profile_id = ? AND usergroup_id = ?
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, groupRole);
            ps.setInt(2, profileId);
            ps.setInt(3, usergroupId);

            ps.executeUpdate();

        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public void delete(int profileId, int usergroupId) {
        String sql = "DELETE FROM profile_usergroup WHERE profile_id = ? AND usergroupId = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, profileId);
            ps.setInt(2, usergroupId);

            ps.executeUpdate();

        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }
}

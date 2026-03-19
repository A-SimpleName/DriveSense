package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.dto.response.GroupMemberResponse;
import com.drivesense.model.ProfileUsergroup;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

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

    public void updateRole(ProfileUsergroup pu) {
        String sql = """
        UPDATE profile_usergroup
        SET group_role = ? 
        WHERE profile_id = ? AND usergroup_id = ?
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, pu.getGroupRole());
            ps.setInt(2, pu.getProfileId());
            ps.setInt(3, pu.getUsergroupId());

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

    public ProfileUsergroup getByProfileIdAndGroupId(int profileId, int usergroupId) {
        String sql = "SELECT * FROM profile_usergroup WHERE profile_id = ? AND usergroup_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            ProfileUsergroup profileUsergroup = new ProfileUsergroup();
            if (rs.next()) {
                return map(rs);
            }
            return profileUsergroup;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public List<GroupMemberResponse> getMembersByGroupId(int groupId) {
        String sql = """
            SELECT 
                p.id AS profile_id,
                p.name AS profile_name,
                p.role AS profile_role,
                pu.group_role
            FROM profile_usergroup pu
            JOIN profile p ON p.id = pu.profile_id
            WHERE pu.usergroup_id = ?
            """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setLong(1, groupId);
            ResultSet rs = ps.executeQuery();

            List<GroupMemberResponse> members = new ArrayList<>();
            while (rs.next()) {
                members.add(mapMember(rs));
            }
            return members;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return new ArrayList<>();
        }
    }

    private GroupMemberResponse mapMember(ResultSet rs) throws SQLException {
        GroupMemberResponse member = new GroupMemberResponse();
        member.setProfileId(rs.getInt("profile_id"));
        member.setName(rs.getString("profile_name"));
        member.setGroupRole(rs.getString("group_role"));
        return member;
    }

    private ProfileUsergroup map(ResultSet rs) throws SQLException {
        ProfileUsergroup profileUsergroup = new ProfileUsergroup();
        profileUsergroup.setUsergroupId(rs.getInt("usergroup_id"));
        profileUsergroup.setProfileId(rs.getInt("profile_id"));
        profileUsergroup.setGroupRole(rs.getString("group_role"));
        return profileUsergroup;
    }
}

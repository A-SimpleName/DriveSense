package com.drivesense.db;

import com.drivesense.App;
import com.drivesense.DbConnection;
import com.drivesense.model.UserGroup;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Repository
public class UserGroupDao {

    @Autowired
    private DbConnection dbConnection;

    public UserGroup insert(UserGroup userGroup) {
        String sql = "INSERT INTO user_group (name, owner_id) VALUES (?,?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1,userGroup.getName());
            ps.setInt(2,userGroup.getOwner_id());

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                userGroup.setId(rs.getInt(1));
            }
            return userGroup;
        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public UserGroup getById(int id) {
        String sql = "SELECT * FROM user_group WHERE id = ?";

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

    public List<UserGroup> getAll () {
        String sql = "SELECT * FROM user_group";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<UserGroup> userGroups = new ArrayList<>();
            while (rs.next()) {
                userGroups.add(map(rs));
            }
            return userGroups;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public void update(UserGroup userGroup) {
        String sql = "UPDATE user_group SET name = ?,owner_id = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, userGroup.getName());
            ps.setInt(2,userGroup.getOwner_id());
            ps.setInt(3,userGroup.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM user_group WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    private UserGroup map(ResultSet rs) throws SQLException {
        UserGroup userGroup = new UserGroup();
        userGroup.setId(rs.getInt("id"));
        userGroup.setName(rs.getString("name"));
        userGroup.setOwner_id(rs.getInt("owner_id"));
        return userGroup;
    }
}

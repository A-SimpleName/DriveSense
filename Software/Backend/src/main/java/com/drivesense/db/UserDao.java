package com.drivesense.db;

import com.drivesense.App;
import com.drivesense.DbConnection;
import com.drivesense.model.User;
import org.springframework.beans.factory.annotation.Autowired;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserDao {

    @Autowired
    private DbConnection dbConnection;

    public User insertUser(User user) {
        String sql = "INSERT INTO user (name, role, account_id, group_id) VALUES (?,?,?,?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1,user.getName());
            ps.setString(2,user.getRole());
            ps.setInt(3,user.getAccount_id());
            ps.setInt(4,user.getGroup_id());

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                user.setId(rs.getInt(1));
            }
            return user;
        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public User findById(int id) {
        String sql = "SELECT * FROM user WHERE id = ?";

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

    public List<User> findByGroup_id(int group_id) {
        String sql = "SELECT * FROM user WHERE group_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, group_id);
            ResultSet rs = ps.executeQuery();
            List<User> users = new ArrayList<>();

            while (rs.next()) {
                users.add(map(rs));
            }
            return users;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public List<User> findAll () {
        String sql = "SELECT * FROM user";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<User> users = new ArrayList<>();
            while (rs.next()) {
                users.add(map(rs));
            }
            return users;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public void update(User user) {
        String sql = "UPDATE user SET name = ?, role = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, user.getName());
            ps.setString(2, user.getRole());
            ps.setInt(3,user.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM user WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public List<User> findAllUsersByAccount_id(int id) {
        String sql = "SELECT * FROM user WHERE account_id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1,id);
            ResultSet rs = ps.executeQuery();
            List<User> users = new ArrayList<>();
            while (rs.next()) {
                users.add(map(rs));
            }
            return users;
        } catch(SQLException e) {
            System.err.println(e.getMessage());
            return new ArrayList<>();
        }
    }

    private User map(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(rs.getInt("id"));
        user.setName(rs.getString("name"));
        user.setRole(rs.getString("role"));
        user.setAccount_id(rs.getInt("account_id"));
        user.setGroup_id(rs.getInt("group_id"));
        return user;
    }

}

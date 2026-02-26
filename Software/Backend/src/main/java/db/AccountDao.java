package db;

import app.App;
import model.Account;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class AccountDao {
    public static void insertAccount(Account acc) {
        String sql = "INSERT INTO account (fname, lname, pwd, email) VALUES (?,?,?,?)";
        try (Connection conn = App.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1,acc.getfName());
            ps.setString(2,acc.getlName());
            ps.setString(3,acc.getPassword());
            ps.setString(4,acc.getEmail());

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                acc.setId(rs.getInt(1));
            }
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static Account findById(int id) {
        String sql = "SELECT * FROM account WHERE id = ?";

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

    public static Account findByEmail (String email) {
        String sql = "SELECT * FROM account WHERE email = ?";

        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, email);
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

    public static List<Account> findAll () {
        String sql = "SELECT * FROM account";

        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<Account> accounts = new ArrayList<>();
            while (rs.next()) {
                accounts.add(map(rs));
            }
            return accounts;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public static void update(Account acc) {
        String sql = "UPDATE account SET fname = ?, lname = ?, pwd = ?, email = ? WHERE id = ?";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, acc.getfName());
            ps.setString(2, acc.getlName());
            ps.setString(3, acc.getPassword());
            ps.setString(4, acc.getEmail());
            ps.setInt(5, acc.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static void updatePassword (int id, String password) {
        String sql = "UPDATE account SET pwd = ? WHERE id = ?";

        try (Connection conn = App.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1,password);
            ps.setInt(2,id);

            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static void deleteById(int id) {
        String sql = "DELETE FROM account WHERE id = ?";
        try (Connection conn = App.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }
    }

    public static Account map(ResultSet rs) throws SQLException {
        Account acc = new Account();
        acc.setId(rs.getInt("id"));
        acc.setfName(rs.getString("fname"));
        acc.setlName(rs.getString("lname"));
        acc.setEmail(rs.getString("email"));
        acc.setPassword(rs.getString("pwd"));
        return acc;
    }
}

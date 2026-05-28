package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.exceptions.*;
import com.drivesense.model.Account;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;


import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Repository
public class AccountDao {

    @Autowired
    private DbConnection dbConnection;

    public Account insert(Account acc) {
        String sql = "INSERT INTO account (fname, lname, pwd, email, birthdate) VALUES (?,?,?,?, ?)";
        try (Connection conn = dbConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1,acc.getfName());
            ps.setString(2,acc.getlName());
            ps.setString(3,acc.getPassword());
            ps.setString(4,acc.getEmail());
            if (acc.getBirthdate() != null) {
                ps.setDate(5, Date.valueOf(acc.getBirthdate()));
            } else {
                ps.setNull(5, Types.DATE);
            }

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                acc.setId(rs.getInt(1));
            }
            return acc;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim speichern des Accounts", e);
        }
    }

    public Account getById(int id) {
        String sql = "SELECT * FROM account WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return map(rs);
            }
            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Accounts", e);
        }
    }

    public Account getByEmail (String email) {
        String sql = "SELECT * FROM account WHERE email = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, email);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return map(rs);
            }

            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Accounts", e);
        }
    }

    public List<Account> getAll () {
        String sql = "SELECT * FROM account";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<Account> accounts = new ArrayList<>();
            while (rs.next()) {
                accounts.add(map(rs));
            }
            return accounts;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden der Accounts", e);
        }
    }

    public void update(Account account) {
        String sql = "UPDATE account SET fname = ?, lname = ?, email = ?, pending_email = ?, email_verified = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, account.getfName());
            ps.setString(2, account.getlName());
            ps.setString(3, account.getEmail());
            ps.setString(4, account.getPendingEmail());
            ps.setBoolean(5, account.isEmailVerified());
            ps.setInt(6, account.getId());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Accounts", e);
        }
    }

    public void updatePassword (int id, String password) {
        String sql = "UPDATE account SET pwd = ? WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1,password);
            ps.setInt(2,id);

            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Passworts", e);
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM account WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim löschen des Accounts", e);
        }
    }

    public void setEmailVerified(int accountId) {
        String sql = "UPDATE account SET email_verified = true WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Verifizieren des Accounts", e);
        }
    }

    public void deleteUnverifiedOlderThan24Hours() {
        String sql = """
        DELETE FROM account
        WHERE email_verified = false
        AND created_at < NOW() - INTERVAL 24 HOUR
        """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Löschen nicht verifizierter Accounts", e);
        }
    }

    private Account map(ResultSet rs) throws SQLException {
        Account acc = new Account();
        acc.setId(rs.getInt("id"));
        acc.setfName(rs.getString("fname"));
        acc.setlName(rs.getString("lname"));
        acc.setEmail(rs.getString("email"));
        acc.setPassword(rs.getString("pwd"));
        acc.setPendingEmail(rs.getString("pending_email"));
        Date date = rs.getDate("birthdate");
        acc.setEmailVerified(rs.getBoolean("email_verified"));
        if (date != null) {
            acc.setBirthdate(date.toLocalDate());
        }
        return acc;
    }
}
